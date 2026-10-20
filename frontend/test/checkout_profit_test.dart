import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:tindagrid/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3.5: Dynamic Cart, Profit Tracking & Dual-Payment Checkout Tests', () {
    test('Calculates cart item subtotal, profit margin, and total profit', () {
      // Item A: Selling 15, Cost 11, Qty 2 -> Subtotal 30, Cost 22, Profit 8
      const itemPriceA = 15.0;
      const itemCostA = 11.0;
      const qtyA = 2;
      final subtotalA = itemPriceA * qtyA;
      final profitA = (itemPriceA - itemCostA) * qtyA;

      // Item B: Selling 50, Cost 40, Qty 1 -> Subtotal 50, Cost 40, Profit 10
      const itemPriceB = 50.0;
      const itemCostB = 40.0;
      const qtyB = 1;
      final subtotalB = itemPriceB * qtyB;
      final profitB = (itemPriceB - itemCostB) * qtyB;

      final totalCartPrice = subtotalA + subtotalB; // 80.0
      final totalCartProfit = profitA + profitB; // 18.0
      final profitMargin = (totalCartProfit / totalCartPrice) * 100; // 22.5%

      expect(totalCartPrice, equals(80.0));
      expect(totalCartProfit, equals(18.0));
      expect(profitMargin, closeTo(22.5, 0.01));
    });

    test('Cash Checkout records sale atomically with tender and change', () async {
      // 1. Setup product
      await db.into(db.products).insert(
            const ProductsCompanion(
              id: Value('prod-bearbrand-1'),
              name: Value('Bear Brand 33g'),
              barcode: Value('4800361391851'),
              category: Value('Beverages'),
              costPrice: Value(12.0),
              sellingPrice: Value(15.0),
              currentStock: Value(20.0),
              unit: Value('sachet'),
            ),
          );

      // 2. Prepare checkout items
      final saleItems = [
        const SaleItemsCompanion(
          id: Value('item-1'),
          saleId: Value(''), // populated in recordSale
          productId: Value('prod-bearbrand-1'),
          productName: Value('Bear Brand 33g'),
          quantity: Value(2.0),
          costPrice: Value(12.0),
          unitPrice: Value(15.0),
          subtotal: Value(30.0),
          profit: Value(6.0),
        ),
      ];

      const total = 30.0;
      const tendered = 50.0;
      const sukli = tendered - total; // 20.0

      // 3. Record cash sale
      final saleId = await db.recordSale(
        paymentMethod: 'CASH',
        totalAmount: total,
        amountReceived: tendered,
        sukliAmount: sukli,
        items: saleItems,
      );

      expect(saleId, isNotEmpty);

      // Verify sale persisted
      final saleRecord = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();
      expect(saleRecord.paymentMethod, equals('CASH'));
      expect(saleRecord.totalAmount, equals(30.0));
      expect(saleRecord.amountReceived, equals(50.0));
      expect(saleRecord.sukliAmount, equals(20.0));
      expect(saleRecord.totalProfit, equals(6.0));

      // Verify inventory decremented: 20 - 2 = 18
      final prod = await (db.select(db.products)..where((p) => p.id.equals('prod-bearbrand-1'))).getSingle();
      expect(prod.currentStock, equals(18.0));
    });

    test('GCash Checkout records sale and logs store payment entry', () async {
      final saleItems = [
        const SaleItemsCompanion(
          id: Value('item-2'),
          saleId: Value(''),
          productId: Value('prod-coke-1'),
          productName: Value('Coke 1.5L'),
          quantity: Value(1.0),
          costPrice: Value(55.0),
          unitPrice: Value(70.0),
          subtotal: Value(70.0),
          profit: Value(15.0),
        ),
      ];

      final saleId = await db.recordSale(
        paymentMethod: 'GCASH',
        totalAmount: 70.0,
        amountReceived: 70.0,
        sukliAmount: 0.0,
        items: saleItems,
      );

      const refNo = 'GCASH-99128471';
      await db.recordGcash(
        transactionType: 'STORE_PAYMENT',
        amount: 70.0,
        feeCharged: 0.0,
        referenceNumber: refNo,
        notes: 'POS Sale #$saleId',
      );

      // Verify GCash ledger contains payment
      final gcashEntries = await db.select(db.gcashLedger).get();
      expect(gcashEntries.length, equals(1));
      expect(gcashEntries.first.transactionType, equals('STORE_PAYMENT'));
      expect(gcashEntries.first.amount, equals(70.0));
      expect(gcashEntries.first.referenceNumber, equals(refNo));
      expect(gcashEntries.first.notes, contains(saleId));
    });
  });
}
