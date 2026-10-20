import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindagrid/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase Unit Tests', () {
    test('Can insert and search products by barcode', () async {
      await db.saveProduct(
        const ProductsCompanion(
          id: Value('prod-1'),
          barcode: Value('4800016644818'),
          name: Value('Silver Swan Soy Sauce 200ml'),
          category: Value('Condiments'),
          costPrice: Value(15.0),
          sellingPrice: Value(18.0),
          currentStock: Value(24.0),
        ),
      );

      final found = await db.getProductByBarcode('4800016644818');
      expect(found, isNotNull);
      expect(found!.name, 'Silver Swan Soy Sauce 200ml');
      expect(found.sellingPrice, 18.0);
    });

    test('Stock adjustment records inventory audit log', () async {
      await db.saveProduct(
        const ProductsCompanion(
          id: Value('prod-2'),
          name: Value('Lucky Me Pancit Canton Kalamansi'),
          costPrice: Value(12.0),
          sellingPrice: Value(15.0),
          currentStock: Value(10.0),
        ),
      );

      // Restock 20 packs
      await db.adjustStock(
        productId: 'prod-2',
        changeQuantity: 20.0,
        reason: 'restock',
        notes: 'Delivery from Puregold',
      );

      final products = await db.searchProducts('Lucky Me');
      expect(products.first.currentStock, 30.0);

      // Verify inventory log
      final logs = await db.select(db.inventoryLogs).get();
      expect(logs.length, 1);
      expect(logs.first.changeQuantity, 20.0);
      expect(logs.first.reason, 'restock');
    });

    test('Sale transaction decrements inventory and records sale items atomically', () async {
      await db.saveProduct(
        const ProductsCompanion(
          id: Value('prod-3'),
          name: Value('Bear Brand Fortified 33g'),
          costPrice: Value(10.0),
          sellingPrice: Value(13.0),
          currentStock: Value(50.0),
        ),
      );

      // Customer buys 5 sachets for ₱65 (paid ₱100, sukli ₱35)
      final saleId = await db.recordSale(
        paymentMethod: 'CASH',
        totalAmount: 65.0,
        amountReceived: 100.0,
        sukliAmount: 35.0,
        items: [
          const SaleItemsCompanion(
            id: Value('item-1'),
            saleId: Value(''), // Assigned in transaction
            productId: Value('prod-3'),
            productName: Value('Bear Brand Fortified 33g'),
            quantity: Value(5.0),
            costPrice: Value(10.0),
            unitPrice: Value(13.0),
            subtotal: Value(65.0),
            profit: Value(15.0),
          ),
        ],
      );

      expect(saleId, isNotEmpty);

      // Verify product stock decremented from 50 to 45
      final updatedProduct = await (db.select(db.products)..where((p) => p.id.equals('prod-3'))).getSingle();
      expect(updatedProduct.currentStock, 45.0);

      // Verify sync queue has the sale queued
      final syncQueue = await db.getPendingSyncQueue();
      expect(syncQueue.any((q) => q.entityTable == 'sales' && q.entityId == saleId), isTrue);
    });

    test('Customer Pautang ledger tracks balance and partial payments', () async {
      final debtId = await db.recordDebt(
        customerName: 'Aling Nena',
        customerPhone: '09171234567',
        totalAmount: 250.0,
        items: [
          const DebtItemsCompanion(
            id: Value('debt-item-1'),
            debtId: Value(''),
            description: Value('2x Canned Goods, 1kg Rice'),
            amount: Value(250.0),
          ),
        ],
      );

      var activeDebts = await db.watchActiveDebts().first;
      expect(activeDebts.length, 1);
      expect(activeDebts.first.remainingBalance, 250.0);
      expect(activeDebts.first.status, 'PENDING');

      // Aling Nena pays ₱150 partial
      await db.payDebt(debtId, 150.0);
      activeDebts = await db.watchActiveDebts().first;
      expect(activeDebts.first.remainingBalance, 100.0);
      expect(activeDebts.first.status, 'PARTIALLY_PAID');

      // Aling Nena pays remaining ₱100
      await db.payDebt(debtId, 100.0);
      activeDebts = await db.watchActiveDebts().first;
      expect(activeDebts.isEmpty, isTrue); // No longer in active debts
    });

    test('GCash cash-out logging with convenience fee', () async {
      await db.recordGcash(
        transactionType: 'CASH_OUT',
        amount: 500.0,
        feeCharged: 15.0,
        referenceNumber: '987654321',
        customerName: 'Kuya Jojo',
      );

      final txns = await db.watchGcashTransactions().first;
      expect(txns.length, 1);
      expect(txns.first.transactionType, 'CASH_OUT');
      expect(txns.first.feeCharged, 15.0);
    });
  });
}
