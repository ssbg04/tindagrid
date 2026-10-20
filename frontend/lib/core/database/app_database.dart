import 'dart:convert';
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
class DualFloatBalance {
  final double gcashFloat;
  final double cashDrawer;
  final double totalFeesEarned;
  final int totalTransactions;
  final int cashInCount;
  final int cashOutCount;
  final int storePaymentCount;

  const DualFloatBalance({
    required this.gcashFloat,
    required this.cashDrawer,
    required this.totalFeesEarned,
    required this.totalTransactions,
    required this.cashInCount,
    required this.cashOutCount,
    required this.storePaymentCount,
  });
}

class AssistantSalesSummary {
  final int totalSalesCount;
  final double totalRevenue;
  final double totalProfit;
  final double cashRevenue;
  final double gcashRevenue;

  const AssistantSalesSummary({
    required this.totalSalesCount,
    required this.totalRevenue,
    required this.totalProfit,
    required this.cashRevenue,
    required this.gcashRevenue,
  });
}

class AssistantGcashSummary {
  final double totalFees;
  final int cashInCount;
  final double cashInVolume;
  final int cashOutCount;
  final double cashOutVolume;
  final int storePaymentCount;
  final double storePaymentVolume;

  const AssistantGcashSummary({
    required this.totalFees,
    required this.cashInCount,
    required this.cashInVolume,
    required this.cashOutCount,
    required this.cashOutVolume,
    required this.storePaymentCount,
    required this.storePaymentVolume,
  });
}

class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'tindagrid_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
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

  /// Watch unbarcoded or Tingi goods for the Quick-Tap Visual Grid
  Stream<List<Product>> watchTingiProducts() {
    return (select(products)
          ..where((p) => (p.isTingi.equals(true) | p.barcode.isNull() | p.barcode.equals('')) & p.isDeleted.equals(false))
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

  /// Internal helper to enqueue local mutations into sync_queue as JSON
  Future<void> _enqueueSync({
    required String entityTable,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await into(syncQueue).insert(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityTable: entityTable,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(payload),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Upsert a product and log the mutation to the sync queue
  Future<void> saveProduct(ProductsCompanion product) async {
    await transaction(() async {
      await into(products).insertOnConflictUpdate(product);
      final saved = await (select(products)..where((p) => p.id.equals(product.id.value))).getSingle();

      // Enqueue sync operation with full JSON payload
      await _enqueueSync(
        entityTable: 'products',
        entityId: saved.id,
        operation: 'UPSERT',
        payload: {
          'id': saved.id,
          'barcode': saved.barcode,
          'name': saved.name,
          'category': saved.category,
          'costPrice': saved.costPrice,
          'sellingPrice': saved.sellingPrice,
          'currentStock': saved.currentStock,
          'unit': saved.unit,
          'isTingi': saved.isTingi,
          'imageUrl': saved.imageUrl,
          'isDeleted': saved.isDeleted,
          'createdAt': saved.createdAt.toIso8601String(),
          'updatedAt': saved.updatedAt.toIso8601String(),
        },
      );
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
      final now = DateTime.now();

      // Update product current stock
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          currentStock: Value(newStock),
          updatedAt: Value(now),
        ),
      );

      final logId = _uuid.v4();
      // Record audit log
      await into(inventoryLogs).insert(InventoryLogsCompanion.insert(
        id: logId,
        productId: productId,
        changeQuantity: changeQuantity,
        previousStock: current.currentStock,
        newStock: newStock,
        reason: reason,
        notes: Value(notes),
        createdAt: Value(now),
      ));

      // Enqueue product update mutation
      await _enqueueSync(
        entityTable: 'products',
        entityId: productId,
        operation: 'UPDATE',
        payload: {
          'id': current.id,
          'barcode': current.barcode,
          'name': current.name,
          'category': current.category,
          'costPrice': current.costPrice,
          'sellingPrice': current.sellingPrice,
          'currentStock': newStock,
          'unit': current.unit,
          'isTingi': current.isTingi,
          'imageUrl': current.imageUrl,
          'isDeleted': current.isDeleted,
          'updatedAt': now.toIso8601String(),
        },
      );

      // Enqueue inventory audit log mutation
      await _enqueueSync(
        entityTable: 'inventory_logs',
        entityId: logId,
        operation: 'INSERT',
        payload: {
          'id': logId,
          'productId': productId,
          'changeQuantity': changeQuantity,
          'previousStock': current.currentStock,
          'newStock': newStock,
          'reason': reason,
          'notes': notes,
          'createdAt': now.toIso8601String(),
        },
      );
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
        if (item.profit.present) {
          totalProfit += item.profit.value;
        }
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
      final serializedItems = <Map<String, dynamic>>[];
      for (final item in items) {
        final itemWithSaleId = item.copyWith(saleId: Value(saleId));
        await into(saleItems).insert(itemWithSaleId);

        serializedItems.add({
          'id': item.id.present ? item.id.value : _uuid.v4(),
          'productId': item.productId.value,
          'productName': item.productName.value,
          'quantity': item.quantity.present ? item.quantity.value : 1.0,
          'costPrice': item.costPrice.present ? item.costPrice.value : 0.0,
          'unitPrice': item.unitPrice.value,
          'subtotal': item.subtotal.value,
          'profit': item.profit.present ? item.profit.value : 0.0,
        });

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
          final logId = _uuid.v4();
          await into(inventoryLogs).insert(InventoryLogsCompanion.insert(
            id: logId,
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

      // 3. Queue for cloud sync with full sale details and item breakdown
      await _enqueueSync(
        entityTable: 'sales',
        entityId: saleId,
        operation: 'INSERT',
        payload: {
          'id': saleId,
          'timestamp': now.toIso8601String(),
          'paymentMethod': paymentMethod,
          'totalAmount': totalAmount,
          'amountReceived': amountReceived,
          'sukliAmount': sukliAmount,
          'totalProfit': totalProfit,
          'isDebt': isDebt,
          'debtId': debtId,
          'items': serializedItems,
        },
      );
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

      final serializedItems = <Map<String, dynamic>>[];
      for (final item in items) {
        await into(debtItems).insert(item.copyWith(debtId: Value(debtId)));
        serializedItems.add({
          'id': item.id.present ? item.id.value : _uuid.v4(),
          'debtId': debtId,
          'productId': item.productId.present ? item.productId.value : null,
          'description': item.description.value,
          'quantity': item.quantity.present ? item.quantity.value : 1.0,
          'amount': item.amount.value,
        });
      }

      // Enqueue debt for cloud sync
      await _enqueueSync(
        entityTable: 'debts',
        entityId: debtId,
        operation: 'INSERT',
        payload: {
          'id': debtId,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'totalAmount': totalAmount,
          'remainingBalance': totalAmount,
          'borrowedDate': now.toIso8601String(),
          'dueDate': dueDate?.toIso8601String(),
          'status': 'PENDING',
          'notes': notes,
          'items': serializedItems,
          'updatedAt': now.toIso8601String(),
        },
      );
    });

    return debtId;
  }

  /// Record partial or full payment on customer debt
  Future<void> payDebt(String debtId, double paymentAmount) async {
    await transaction(() async {
      final current = await (select(debts)..where((d) => d.id.equals(debtId))).getSingle();
      final newBalance = (current.remainingBalance - paymentAmount).clamp(0.0, double.infinity);
      final newStatus = newBalance <= 0.0 ? 'PAID' : 'PARTIALLY_PAID';
      final now = DateTime.now();

      await (update(debts)..where((d) => d.id.equals(debtId))).write(
        DebtsCompanion(
          remainingBalance: Value(newBalance),
          status: Value(newStatus),
          updatedAt: Value(now),
        ),
      );

      // Enqueue debt update
      await _enqueueSync(
        entityTable: 'debts',
        entityId: debtId,
        operation: 'UPDATE',
        payload: {
          'id': debtId,
          'customerName': current.customerName,
          'customerPhone': current.customerPhone,
          'totalAmount': current.totalAmount,
          'remainingBalance': newBalance,
          'status': newStatus,
          'notes': current.notes,
          'paymentAmount': paymentAmount,
          'updatedAt': now.toIso8601String(),
        },
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

  /// Watch payables due within a specific threshold (e.g. 48 hours for urgent banner alert)
  Stream<List<Payable>> watchPayablesDueSoon({Duration threshold = const Duration(hours: 48)}) {
    final now = DateTime.now();
    final limit = now.add(threshold);
    return (select(payables)
          ..where((p) =>
              (p.status.equals('UNPAID') | p.status.equals('PARTIALLY_PAID')) &
              p.dueDate.isSmallerOrEqualValue(limit))
          ..orderBy([(p) => OrderingTerm.asc(p.dueDate)]))
        .watch();
  }

  /// Get itemized list for a customer debt
  Future<List<DebtItem>> getDebtItems(String debtId) {
    return (select(debtItems)..where((i) => i.debtId.equals(debtId))).get();
  }

  /// Record a new supplier/bodega payable (delivery van, wholesale agent)
  Future<String> recordPayable({
    required String supplierName,
    String? contactNumber,
    required double totalAmount,
    required DateTime dueDate,
    String? reminderNotes,
  }) async {
    final payableId = _uuid.v4();
    final now = DateTime.now();

    await transaction(() async {
      await into(payables).insert(PayablesCompanion.insert(
        id: payableId,
        supplierName: supplierName,
        contactNumber: Value(contactNumber),
        totalAmount: totalAmount,
        paidAmount: const Value(0.0),
        dueDate: dueDate,
        reminderNotes: Value(reminderNotes),
        status: const Value('UNPAID'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      await _enqueueSync(
        entityTable: 'payables',
        entityId: payableId,
        operation: 'INSERT',
        payload: {
          'id': payableId,
          'supplierName': supplierName,
          'contactNumber': contactNumber,
          'totalAmount': totalAmount,
          'paidAmount': 0.0,
          'dueDate': dueDate.toIso8601String(),
          'reminderNotes': reminderNotes,
          'status': 'UNPAID',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
    });

    return payableId;
  }

  /// Record payment to bodega/supplier
  Future<void> paySupplier(String payableId, double amount) async {
    await transaction(() async {
      final current = await (select(payables)..where((p) => p.id.equals(payableId))).getSingle();
      final newPaid = current.paidAmount + amount;
      final newStatus = newPaid >= current.totalAmount ? 'SETTLED' : 'PARTIALLY_PAID';
      final now = DateTime.now();

      await (update(payables)..where((p) => p.id.equals(payableId))).write(
        PayablesCompanion(
          paidAmount: Value(newPaid),
          status: Value(newStatus),
          updatedAt: Value(now),
        ),
      );

      await _enqueueSync(
        entityTable: 'payables',
        entityId: payableId,
        operation: 'UPDATE',
        payload: {
          'id': payableId,
          'supplierName': current.supplierName,
          'paidAmount': newPaid,
          'totalAmount': current.totalAmount,
          'status': newStatus,
          'updatedAt': now.toIso8601String(),
        },
      );
    });
  }

  // --------------------------------------------------------------------------
  // OFFLINE AI ASSISTANT QUERIES
  // --------------------------------------------------------------------------

  /// Query top customers with largest unpaid debt balance
  Future<List<Debt>> getTopDebtors({int limit = 5}) {
    return (select(debts)
          ..where((d) =>
              (d.status.equals('PENDING') | d.status.equals('PARTIALLY_PAID')) &
              d.remainingBalance.isBiggerThanValue(0.0))
          ..orderBy([(d) => OrderingTerm.desc(d.remainingBalance)])
          ..limit(limit))
        .get();
  }

  /// Query products below minimum safety threshold (e.g. 5 units)
  Future<List<Product>> getLowStockProducts({double threshold = 5.0}) {
    return (select(products)
          ..where((p) => p.currentStock.isSmallerOrEqualValue(threshold) & p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.currentStock)]))
        .get();
  }

  /// Query sales summary by date range and payment method
  Future<AssistantSalesSummary> getSalesSummaryForAssistant({DateTime? startDate, DateTime? endDate}) async {
    var query = select(sales);
    if (startDate != null) {
      query = query..where((s) => s.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query = query..where((s) => s.timestamp.isSmallerOrEqualValue(endDate));
    }

    final salesList = await query.get();
    double totalRevenue = 0.0;
    double totalProfit = 0.0;
    double cashRevenue = 0.0;
    double gcashRevenue = 0.0;

    for (final s in salesList) {
      totalRevenue += s.totalAmount;
      totalProfit += s.totalProfit;
      if (s.paymentMethod == 'CASH') {
        cashRevenue += s.totalAmount;
      } else if (s.paymentMethod == 'GCASH') {
        gcashRevenue += s.totalAmount;
      }
    }

    return AssistantSalesSummary(
      totalSalesCount: salesList.length,
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      cashRevenue: cashRevenue,
      gcashRevenue: gcashRevenue,
    );
  }

  /// Query GCash fees profit and transaction counts
  Future<AssistantGcashSummary> getGcashProfitSummaryForAssistant({DateTime? startDate, DateTime? endDate}) async {
    var query = select(gcashLedger);
    if (startDate != null) {
      query = query..where((g) => g.timestamp.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query = query..where((g) => g.timestamp.isSmallerOrEqualValue(endDate));
    }

    final list = await query.get();
    double totalFees = 0.0;
    int cashInCount = 0;
    double cashInVolume = 0.0;
    int cashOutCount = 0;
    double cashOutVolume = 0.0;
    int storePaymentCount = 0;
    double storePaymentVolume = 0.0;

    for (final tx in list) {
      totalFees += tx.feeCharged;
      if (tx.transactionType == 'CASH_IN') {
        cashInCount++;
        cashInVolume += tx.amount;
      } else if (tx.transactionType == 'CASH_OUT') {
        cashOutCount++;
        cashOutVolume += tx.amount;
      } else if (tx.transactionType == 'STORE_PAYMENT') {
        storePaymentCount++;
        storePaymentVolume += tx.amount;
      }
    }

    return AssistantGcashSummary(
      totalFees: totalFees,
      cashInCount: cashInCount,
      cashInVolume: cashInVolume,
      cashOutCount: cashOutCount,
      cashOutVolume: cashOutVolume,
      storePaymentCount: storePaymentCount,
      storePaymentVolume: storePaymentVolume,
    );
  }

  /// Query upcoming supplier payables
  Future<List<Payable>> getUpcomingPayables({int limit = 5}) {
    return (select(payables)
          ..where((p) => p.status.equals('UNPAID') | p.status.equals('PARTIALLY_PAID'))
          ..orderBy([(p) => OrderingTerm.asc(p.dueDate)])
          ..limit(limit))
        .get();
  }

  // --------------------------------------------------------------------------
  // GCASH LEDGER OPERATIONS & DUAL-FLOAT ENGINE
  // --------------------------------------------------------------------------

  /// Watch GCash transaction history
  Stream<List<GcashTransaction>> watchGcashTransactions() {
    return (select(gcashLedger)..orderBy([(g) => OrderingTerm.desc(g.timestamp)])).watch();
  }

  /// Check if a GCash reference number has already been logged (anti-fraud/scam check)
  Future<bool> isReferenceNumberUsed(String refNo) async {
    final clean = refNo.replaceAll(RegExp(r'\s+'), '').trim();
    if (clean.isEmpty) return false;
    final all = await select(gcashLedger).get();
    return all.any((t) =>
        t.referenceNumber != null &&
        t.referenceNumber!.replaceAll(RegExp(r'\s+'), '').trim().toLowerCase() == clean.toLowerCase());
  }

  /// Record GCash cash-in / cash-out with convenience fee
  Future<String> recordGcash({
    required String transactionType,
    required double amount,
    required double feeCharged,
    String? referenceNumber,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    final gcashId = _uuid.v4();
    final now = DateTime.now();

    await transaction(() async {
      await into(gcashLedger).insert(GcashLedgerCompanion.insert(
        id: gcashId,
        transactionType: transactionType,
        amount: amount,
        feeCharged: Value(feeCharged),
        referenceNumber: Value(referenceNumber),
        customerName: Value(customerName),
        customerPhone: Value(customerPhone),
        timestamp: Value(now),
        notes: Value(notes),
      ));

      await _enqueueSync(
        entityTable: 'gcash_ledger',
        entityId: gcashId,
        operation: 'INSERT',
        payload: {
          'id': gcashId,
          'transactionType': transactionType,
          'amount': amount,
          'feeCharged': feeCharged,
          'referenceNumber': referenceNumber,
          'customerName': customerName,
          'customerPhone': customerPhone,
          'timestamp': now.toIso8601String(),
          'notes': notes,
        },
      );
    });

    return gcashId;
  }

  /// Alias for recordGcash to support flexible naming
  Future<String> recordGcashEntry({
    required String transactionType,
    required double amount,
    required double feeCharged,
    String? referenceNumber,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) => recordGcash(
    transactionType: transactionType,
    amount: amount,
    feeCharged: feeCharged,
    referenceNumber: referenceNumber,
    customerName: customerName,
    customerPhone: customerPhone,
    notes: notes,
  );

  /// Watch customizable fee schedule brackets
  Stream<List<GcashFeeBracket>> watchFeeBrackets() {
    return (select(gcashFeeConfig)..orderBy([(b) => OrderingTerm.asc(b.minAmount)])).watch();
  }

  /// Get current fee brackets
  Future<List<GcashFeeBracket>> getFeeBrackets() {
    return (select(gcashFeeConfig)..orderBy([(b) => OrderingTerm.asc(b.minAmount)])).get();
  }

  /// Seed default Philippine sari-sari store fee schedule if empty
  Future<void> seedDefaultFeeBrackets() async {
    final existing = await select(gcashFeeConfig).get();
    if (existing.isNotEmpty) return;

    final defaultBrackets = [
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 1.0,
        maxAmount: 500.0,
        fixedFee: const Value(10.0),
        percentageFee: const Value(0.0),
      ),
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 501.0,
        maxAmount: 1000.0,
        fixedFee: const Value(15.0),
        percentageFee: const Value(0.0),
      ),
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 1001.0,
        maxAmount: 1500.0,
        fixedFee: const Value(20.0),
        percentageFee: const Value(0.0),
      ),
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 1501.0,
        maxAmount: 2000.0,
        fixedFee: const Value(25.0),
        percentageFee: const Value(0.0),
      ),
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 2001.0,
        maxAmount: 3000.0,
        fixedFee: const Value(35.0),
        percentageFee: const Value(0.0),
      ),
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 3001.0,
        maxAmount: 5000.0,
        fixedFee: const Value(50.0),
        percentageFee: const Value(0.0),
      ),
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 5001.0,
        maxAmount: 10000.0,
        fixedFee: const Value(0.0),
        percentageFee: const Value(1.5),
      ),
      GcashFeeConfigCompanion.insert(
        id: _uuid.v4(),
        minAmount: 10001.0,
        maxAmount: 50000.0,
        fixedFee: const Value(0.0),
        percentageFee: const Value(2.0),
      ),
    ];

    for (final bracket in defaultBrackets) {
      await into(gcashFeeConfig).insert(bracket);
    }
  }

  /// Upsert a fee bracket with cloud sync queueing
  Future<void> saveFeeBracket(GcashFeeConfigCompanion bracket) async {
    await into(gcashFeeConfig).insertOnConflictUpdate(bracket);
    await _enqueueSync(
      entityTable: 'gcash_fee_config',
      entityId: bracket.id.value,
      operation: 'UPSERT',
      payload: {
        'id': bracket.id.value,
        'minAmount': bracket.minAmount.value,
        'maxAmount': bracket.maxAmount.value,
        'fixedFee': bracket.fixedFee.present ? bracket.fixedFee.value : 0.0,
        'percentageFee': bracket.percentageFee.present ? bracket.percentageFee.value : 0.0,
      },
    );
  }

  /// Delete a fee bracket with sync queueing
  Future<void> deleteFeeBracket(String id) async {
    await (delete(gcashFeeConfig)..where((b) => b.id.equals(id))).go();
    await _enqueueSync(
      entityTable: 'gcash_fee_config',
      entityId: id,
      operation: 'DELETE',
      payload: {'id': id},
    );
  }

  /// Calculate convenience fee for a given amount using active brackets
  Future<double> calculateGcashFee(double amount) async {
    final brackets = await getFeeBrackets();
    for (final b in brackets) {
      if (amount >= b.minAmount && amount <= b.maxAmount) {
        if (b.percentageFee > 0) {
          return (amount * (b.percentageFee / 100.0));
        }
        return b.fixedFee;
      }
    }
    // Default fallback brackets if table is empty
    if (amount <= 500) return 10.0;
    if (amount <= 1000) return 15.0;
    if (amount <= 1500) return 20.0;
    if (amount <= 2000) return 25.0;
    if (amount <= 3000) return 35.0;
    if (amount <= 5000) return 50.0;
    return (amount * 0.015);
  }

  /// Watch real-time dual-float balances (GCash E-Wallet vs Physical Cash Drawer)
  Stream<DualFloatBalance> watchDualFloatBalance({
    double baseCash = 5000.0,
    double baseGcash = 10000.0,
  }) {
    return watchGcashTransactions().asyncMap((txList) async {
      final cashSales = await (select(sales)..where((s) => s.paymentMethod.equals('CASH'))).get();

      double gcash = baseGcash;
      double cash = baseCash;
      double fees = 0.0;
      int cashIn = 0;
      int cashOut = 0;
      int storePay = 0;

      for (final tx in txList) {
        fees += tx.feeCharged;
        if (tx.transactionType == 'CASH_IN') {
          cashIn++;
          gcash -= tx.amount; // Store sent GCash
          cash += (tx.amount + tx.feeCharged); // Store received cash + fee
        } else if (tx.transactionType == 'CASH_OUT') {
          cashOut++;
          gcash += tx.amount; // Store received GCash
          cash -= (tx.amount - tx.feeCharged); // Cash given to customer minus fee
        } else if (tx.transactionType == 'STORE_PAYMENT') {
          storePay++;
          gcash += tx.amount; // Direct store sale paid to GCash
        } else if (tx.transactionType == 'FLOAT_ADJUSTMENT') {
          gcash += tx.amount;
        }
      }

      for (final s in cashSales) {
        cash += s.totalAmount;
      }

      return DualFloatBalance(
        gcashFloat: gcash,
        cashDrawer: cash,
        totalFeesEarned: fees,
        totalTransactions: txList.length,
        cashInCount: cashIn,
        cashOutCount: cashOut,
        storePaymentCount: storePay,
      );
    });
  }

  // --------------------------------------------------------------------------
  // SYNC QUEUE OPERATIONS & REPLICATION METHODS
  // --------------------------------------------------------------------------

  /// Watch real-time count of pending sync mutations for UI badge
  Stream<int> watchPendingSyncCount() {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([countExp])
      ..where(syncQueue.status.equals('PENDING'));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Get pending mutation logs to sync to cloud
  Future<List<SyncQueueEntry>> getPendingSyncQueue({int limit = 100}) {
    return (select(syncQueue)
          ..where((s) => s.status.equals('PENDING'))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Mark single sync queue item as completed
  Future<void> markSyncSuccess(String id) {
    return (update(syncQueue)..where((s) => s.id.equals(id))).write(
      const SyncQueueCompanion(status: Value('COMPLETED')),
    );
  }

  /// Mark batch of sync queue items as completed
  Future<void> markSyncSuccessBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(syncQueue)..where((s) => s.id.isIn(ids))).write(
      const SyncQueueCompanion(status: Value('COMPLETED')),
    );
  }

  /// Mark sync queue item as failed with error details and increment retryCount
  Future<void> markSyncFailed(String id, String error) async {
    final item = await (select(syncQueue)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (item != null) {
      await (update(syncQueue)..where((s) => s.id.equals(id))).write(
        SyncQueueCompanion(
          status: const Value('FAILED'),
          retryCount: Value(item.retryCount + 1),
          lastError: Value(error),
        ),
      );
    }
  }

  /// Apply remote products from cloud delta pull with Last-Write-Wins conflict resolution
  Future<void> applyRemoteProducts(List<dynamic> remoteProducts) async {
    await transaction(() async {
      for (final p in remoteProducts) {
        final id = p['id'] as String;
        final remoteUpdated = DateTime.tryParse(p['updatedAt']?.toString() ?? '') ?? DateTime.now();

        final local = await (select(products)..where((prod) => prod.id.equals(id))).getSingleOrNull();
        if (local != null) {
          // Last-Write-Wins: only apply if remote is newer or equal
          if (remoteUpdated.isAfter(local.updatedAt) || remoteUpdated.isAtSameMomentAs(local.updatedAt)) {
            await (update(products)..where((prod) => prod.id.equals(id))).write(
              ProductsCompanion(
                barcode: Value(p['barcode'] as String? ?? local.barcode),
                name: Value(p['name'] as String? ?? local.name),
                category: Value(p['category'] as String? ?? local.category),
                costPrice: Value((p['costPrice'] as num?)?.toDouble() ?? local.costPrice),
                sellingPrice: Value((p['sellingPrice'] as num?)?.toDouble() ?? local.sellingPrice),
                currentStock: Value((p['currentStock'] as num?)?.toDouble() ?? local.currentStock),
                unit: Value(p['unit'] as String? ?? local.unit),
                isTingi: Value(p['isTingi'] as bool? ?? local.isTingi),
                imageUrl: Value(p['imageUrl'] as String? ?? local.imageUrl),
                isDeleted: Value(p['isDeleted'] as bool? ?? local.isDeleted),
                updatedAt: Value(remoteUpdated),
              ),
            );
          }
        } else {
          // New product from cloud
          await into(products).insert(
            ProductsCompanion.insert(
              id: id,
              barcode: Value(p['barcode'] as String?),
              name: p['name'] as String? ?? 'Product',
              category: Value(p['category'] as String? ?? 'General'),
              costPrice: Value((p['costPrice'] as num?)?.toDouble() ?? 0.0),
              sellingPrice: Value((p['sellingPrice'] as num?)?.toDouble() ?? 0.0),
              currentStock: Value((p['currentStock'] as num?)?.toDouble() ?? 0.0),
              unit: Value(p['unit'] as String? ?? 'pcs'),
              isTingi: Value(p['isTingi'] as bool? ?? false),
              imageUrl: Value(p['imageUrl'] as String?),
              isDeleted: Value(p['isDeleted'] as bool? ?? false),
              createdAt: Value(DateTime.tryParse(p['createdAt']?.toString() ?? '') ?? DateTime.now()),
              updatedAt: Value(remoteUpdated),
            ),
          );
        }
      }
    });
  }

  /// Apply remote sales from cloud (additive ledger; idempotent by ID)
  Future<void> applyRemoteSales(List<dynamic> remoteSales) async {
    await transaction(() async {
      for (final s in remoteSales) {
        final id = s['id'] as String;
        final existing = await (select(sales)..where((sale) => sale.id.equals(id))).getSingleOrNull();
        if (existing == null) {
          await into(sales).insert(
            SalesCompanion.insert(
              id: id,
              timestamp: Value(DateTime.tryParse(s['createdAt']?.toString() ?? '') ?? DateTime.now()),
              paymentMethod: Value(s['paymentMethod'] as String? ?? 'CASH'),
              totalAmount: (s['totalAmount'] as num?)?.toDouble() ?? 0.0,
              totalProfit: Value((s['estimatedTubo'] as num?)?.toDouble() ?? 0.0),
              createdAt: Value(DateTime.tryParse(s['createdAt']?.toString() ?? '') ?? DateTime.now()),
            ),
          );
        }
      }
    });
  }

  /// Apply remote debts from cloud with Last-Write-Wins balance updates
  Future<void> applyRemoteDebts(List<dynamic> remoteDebts) async {
    await transaction(() async {
      for (final d in remoteDebts) {
        final id = d['id'] as String;
        final remoteUpdated = DateTime.tryParse(d['updatedAt']?.toString() ?? '') ?? DateTime.now();

        final local = await (select(debts)..where((deb) => deb.id.equals(id))).getSingleOrNull();
        if (local != null) {
          if (remoteUpdated.isAfter(local.updatedAt) || remoteUpdated.isAtSameMomentAs(local.updatedAt)) {
            await (update(debts)..where((deb) => deb.id.equals(id))).write(
              DebtsCompanion(
                customerName: Value(d['customerName'] as String? ?? local.customerName),
                customerPhone: Value(d['customerPhone'] as String? ?? local.customerPhone),
                totalAmount: Value((d['totalAmount'] as num?)?.toDouble() ?? local.totalAmount),
                remainingBalance: Value((d['remainingBalance'] as num?)?.toDouble() ?? local.remainingBalance),
                status: Value(d['status'] as String? ?? local.status),
                dueDate: Value(d['dueDate'] != null ? DateTime.tryParse(d['dueDate'].toString()) : local.dueDate),
                notes: Value(d['notes'] as String? ?? local.notes),
                updatedAt: Value(remoteUpdated),
              ),
            );
          }
        } else {
          await into(debts).insert(
            DebtsCompanion.insert(
              id: id,
              customerName: d['customerName'] as String? ?? 'Customer',
              customerPhone: Value(d['customerPhone'] as String?),
              totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0.0,
              remainingBalance: (d['remainingBalance'] as num?)?.toDouble() ?? ((d['totalAmount'] as num?)?.toDouble() ?? 0.0),
              borrowedDate: Value(DateTime.tryParse(d['createdAt']?.toString() ?? '') ?? DateTime.now()),
              dueDate: Value(d['dueDate'] != null ? DateTime.tryParse(d['dueDate'].toString()) : null),
              status: Value(d['status'] as String? ?? 'PENDING'),
              notes: Value(d['notes'] as String?),
              updatedAt: Value(remoteUpdated),
            ),
          );
        }
      }
    });
  }

  /// Apply remote GCash transactions (additive ledger)
  Future<void> applyRemoteGcash(List<dynamic> remoteGcash) async {
    await transaction(() async {
      for (final g in remoteGcash) {
        final id = g['id'] as String;
        final existing = await (select(gcashLedger)..where((item) => item.id.equals(id))).getSingleOrNull();
        if (existing == null) {
          await into(gcashLedger).insert(
            GcashLedgerCompanion.insert(
              id: id,
              transactionType: g['type'] as String? ?? 'CASH_IN',
              amount: (g['amount'] as num?)?.toDouble() ?? 0.0,
              feeCharged: Value((g['feeCharged'] as num?)?.toDouble() ?? 0.0),
              referenceNumber: Value(g['referenceNumber'] as String?),
              timestamp: Value(DateTime.tryParse(g['createdAt']?.toString() ?? '') ?? DateTime.now()),
            ),
          );
        }
      }
    });
  }

  /// Cloud Disaster Recovery: Rehydrate full store state from cloud snapshot
  Future<void> restoreCloudSnapshot({
    required List<dynamic> remoteProducts,
    required List<dynamic> remoteDebts,
    required List<dynamic> remoteSales,
    required List<dynamic> remoteGcash,
  }) async {
    await transaction(() async {
      // Clear pending queue to avoid echoing restored items back to cloud
      await delete(syncQueue).go();

      await applyRemoteProducts(remoteProducts);
      await applyRemoteDebts(remoteDebts);
      await applyRemoteSales(remoteSales);
      await applyRemoteGcash(remoteGcash);
    });
  }
}

/// Riverpod Provider exposing the single AppDatabase instance across the entire application
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
