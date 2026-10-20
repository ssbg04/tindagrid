import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'tables/products.dart';
import 'tables/inventory_logs.dart';
import 'tables/sales.dart';
import 'tables/debts.dart';
import 'tables/payables.dart';
import 'tables/gcash.dart';
import 'tables/sync_queue.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Products,
  InventoryLogs,
  Sales,
  SaleItems,
  Debts,
  DebtItems,
  Payables,
  GcashLedger,
  GcashFeeConfig,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'tindagrid_db');
  }

  static const _uuid = Uuid();

  // --------------------------------------------------------------------------
  // PRODUCTS & INVENTORY OPERATIONS
  // --------------------------------------------------------------------------

  /// Watch active products for the Tingi Grid & inventory screens (real-time stream)
  Stream<List<Product>> watchAllProducts() {
    return (select(products)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm(expression: p.name)]))
        .watch();
  }

  /// Search product by barcode (exact match for handheld scanner)
  Future<Product?> getProductByBarcode(String barcode) {
    return (select(products)
          ..where((p) => p.barcode.equals(barcode) & p.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Search products by name, barcode, or category (instant search)
  Future<List<Product>> searchProducts(String query) {
    final lowerQuery = '%${query.toLowerCase()}%';
    return (select(products)
          ..where((p) =>
              (p.name.lower().like(lowerQuery) |
                  p.barcode.lower().like(lowerQuery) |
                  p.category.lower().like(lowerQuery)) &
              p.isDeleted.equals(false))
          ..limit(50))
        .get();
  }

  /// Upsert a product and log the mutation to the sync queue
  Future<void> saveProduct(ProductsCompanion product) async {
    await transaction(() async {
      await into(products).insertOnConflictUpdate(product);

      // Enqueue sync operation
      await into(syncQueue).insert(SyncQueueCompanion.insert(
        id: _uuid.v4(),
        entityTable: 'products',
        entityId: product.id.value,
        operation: 'UPSERT',
        payload: product.toString(),
        createdAt: Value(DateTime.now()),
      ));
    });
  }

  /// Adjust stock with audit reason (restock, damage, audit, etc.)
  Future<void> adjustStock({
    required String productId,
    required double changeQuantity,
    required String reason,
    String? notes,
  }) async {
    await transaction(() async {
      final current = await (select(products)..where((p) => p.id.equals(productId))).getSingle();
      final newStock = current.currentStock + changeQuantity;

      // Update product current stock
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          currentStock: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Record audit log
      await into(inventoryLogs).insert(InventoryLogsCompanion.insert(
        id: _uuid.v4(),
        productId: productId,
        changeQuantity: changeQuantity,
        previousStock: current.currentStock,
        newStock: newStock,
        reason: reason,
        notes: Value(notes),
        createdAt: Value(DateTime.now()),
      ));
    });
  }

  // --------------------------------------------------------------------------
  // POS & SALES OPERATIONS
  // --------------------------------------------------------------------------

  /// Process complete POS checkout transaction atomically
  Future<String> recordSale({
    required String paymentMethod,
    required double totalAmount,
    required double amountReceived,
    required double sukliAmount,
    required List<SaleItemsCompanion> items,
    bool isDebt = false,
    String? debtId,
  }) async {
    final saleId = _uuid.v4();
    final now = DateTime.now();

    await transaction(() async {
      double totalProfit = 0;
      for (final item in items) {
        totalProfit += item.profit.value;
      }

      // 1. Insert Master Sale record
      await into(sales).insert(SalesCompanion.insert(
        id: saleId,
        timestamp: Value(now),
        paymentMethod: Value(paymentMethod),
        totalAmount: totalAmount,
        amountReceived: Value(amountReceived),
        sukliAmount: Value(sukliAmount),
        totalProfit: Value(totalProfit),
        isDebt: Value(isDebt),
        debtId: Value(debtId),
        createdAt: Value(now),
      ));

      // 2. Insert items and decrement inventory stock
      for (final item in items) {
        final itemWithSaleId = item.copyWith(saleId: Value(saleId));
        await into(saleItems).insert(itemWithSaleId);

        // Deduct inventory
        final product = await (select(products)..where((p) => p.id.equals(item.productId.value))).getSingleOrNull();
        if (product != null) {
          final newStock = product.currentStock - item.quantity.value;
          await (update(products)..where((p) => p.id.equals(product.id))).write(
            ProductsCompanion(
              currentStock: Value(newStock),
              updatedAt: Value(now),
            ),
          );

          // Inventory log for sale
          await into(inventoryLogs).insert(InventoryLogsCompanion.insert(
            id: _uuid.v4(),
            productId: product.id,
            changeQuantity: -item.quantity.value,
            previousStock: product.currentStock,
            newStock: newStock,
            reason: 'sale',
            notes: Value('Sale #$saleId'),
            createdAt: Value(now),
          ));
        }
      }

      // 3. Queue for cloud sync
      await into(syncQueue).insert(SyncQueueCompanion.insert(
        id: _uuid.v4(),
        entityTable: 'sales',
        entityId: saleId,
        operation: 'INSERT',
        payload: '{"id": "$saleId", "total": $totalAmount, "items": ${items.length}}',
        createdAt: Value(now),
      ));
    });

    return saleId;
  }

  /// Watch total sales for today (real-time store ticker)
  Stream<List<Sale>> watchTodaySales() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return (select(sales)
          ..where((s) => s.timestamp.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(s) => OrderingTerm.desc(s.timestamp)]))
        .watch();
  }

  // --------------------------------------------------------------------------
  // PAUTANG (DEBTS) OPERATIONS
  // --------------------------------------------------------------------------

  /// Watch active pending customer debts
  Stream<List<Debt>> watchActiveDebts() {
    return (select(debts)
          ..where((d) => d.status.equals('PENDING') | d.status.equals('PARTIALLY_PAID'))
          ..orderBy([(d) => OrderingTerm.desc(d.borrowedDate)]))
        .watch();
  }

  /// Create a new Pautang entry with items
  Future<String> recordDebt({
    required String customerName,
    String? customerPhone,
    required double totalAmount,
    DateTime? dueDate,
    String? notes,
    required List<DebtItemsCompanion> items,
  }) async {
    final debtId = _uuid.v4();
    final now = DateTime.now();

    await transaction(() async {
      await into(debts).insert(DebtsCompanion.insert(
        id: debtId,
        customerName: customerName,
        customerPhone: Value(customerPhone),
        totalAmount: totalAmount,
        remainingBalance: totalAmount,
        borrowedDate: Value(now),
        dueDate: Value(dueDate),
        status: const Value('PENDING'),
        notes: Value(notes),
        updatedAt: Value(now),
      ));

      for (final item in items) {
        await into(debtItems).insert(item.copyWith(debtId: Value(debtId)));
      }
    });

    return debtId;
  }

  /// Record partial or full payment on customer debt
  Future<void> payDebt(String debtId, double paymentAmount) async {
    await transaction(() async {
      final current = await (select(debts)..where((d) => d.id.equals(debtId))).getSingle();
      final newBalance = (current.remainingBalance - paymentAmount).clamp(0.0, double.infinity);
      final newStatus = newBalance <= 0.0 ? 'PAID' : 'PARTIALLY_PAID';

      await (update(debts)..where((d) => d.id.equals(debtId))).write(
        DebtsCompanion(
          remainingBalance: Value(newBalance),
          status: Value(newStatus),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // --------------------------------------------------------------------------
  // PAYABLES (SUPPLIER / BODEGA) OPERATIONS
  // --------------------------------------------------------------------------

  /// Watch pending bodega/supplier payables
  Stream<List<Payable>> watchPendingPayables() {
    return (select(payables)
          ..where((p) => p.status.equals('UNPAID') | p.status.equals('PARTIALLY_PAID'))
          ..orderBy([(p) => OrderingTerm.asc(p.dueDate)]))
        .watch();
  }

  /// Record payment to bodega/supplier
  Future<void> paySupplier(String payableId, double amount) async {
    await transaction(() async {
      final current = await (select(payables)..where((p) => p.id.equals(payableId))).getSingle();
      final newPaid = current.paidAmount + amount;
      final newStatus = newPaid >= current.totalAmount ? 'SETTLED' : 'PARTIALLY_PAID';

      await (update(payables)..where((p) => p.id.equals(payableId))).write(
        PayablesCompanion(
          paidAmount: Value(newPaid),
          status: Value(newStatus),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // --------------------------------------------------------------------------
  // GCASH LEDGER OPERATIONS
  // --------------------------------------------------------------------------

  /// Watch GCash transaction history
  Stream<List<GcashTransaction>> watchGcashTransactions() {
    return (select(gcashLedger)..orderBy([(g) => OrderingTerm.desc(g.timestamp)])).watch();
  }

  /// Record GCash cash-in / cash-out with convenience fee
  Future<void> recordGcash({
    required String transactionType,
    required double amount,
    required double feeCharged,
    String? referenceNumber,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    await into(gcashLedger).insert(GcashLedgerCompanion.insert(
      id: _uuid.v4(),
      transactionType: transactionType,
      amount: amount,
      feeCharged: Value(feeCharged),
      referenceNumber: Value(referenceNumber),
      customerName: Value(customerName),
      customerPhone: Value(customerPhone),
      timestamp: Value(DateTime.now()),
      notes: Value(notes),
    ));
  }

  // --------------------------------------------------------------------------
  // SYNC QUEUE OPERATIONS
  // --------------------------------------------------------------------------

  /// Get pending mutation logs to sync to cloud
  Future<List<SyncQueueEntry>> getPendingSyncQueue({int limit = 100}) {
    return (select(syncQueue)
          ..where((s) => s.status.equals('PENDING'))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Mark sync queue item as completed
  Future<void> markSyncSuccess(String id) {
    return (update(syncQueue)..where((s) => s.id.equals(id))).write(
      const SyncQueueCompanion(status: Value('COMPLETED')),
    );
  }
}

/// Riverpod Provider exposing the single AppDatabase instance across the entire application
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
