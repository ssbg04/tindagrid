import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:tindagrid/core/database/app_database.dart';
import 'package:tindagrid/features/assistant/offline_assistant_engine.dart';

void main() {
  late AppDatabase db;
  late OfflineAssistantEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = OfflineAssistantEngine(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 6: Mini Offline Local AI Assistant Tests', () {
    test('6.1 Intent Classifier maps Taglish NLP queries to correct structured intents', () {
      expect(
        OfflineAssistantEngine.classifyIntent('Sino may pinakamalaking utang?'),
        equals(AssistantIntent.topDebtors),
      );
      expect(
        OfflineAssistantEngine.classifyIntent('Anong mga paninda ang kulang o paubos na ang stock?'),
        equals(AssistantIntent.lowStock),
      );
      expect(
        OfflineAssistantEngine.classifyIntent('Magkano ang benta kahapon?'),
        equals(AssistantIntent.salesSummary),
      );
      expect(
        OfflineAssistantEngine.classifyIntent('Magkano kinita sa patong ng GCash fee?'),
        equals(AssistantIntent.gcashProfit),
      );
      expect(
        OfflineAssistantEngine.classifyIntent('May bayarin ba tayo sa bodega at delivery van?'),
        equals(AssistantIntent.supplierPayables),
      );
      expect(
        OfflineAssistantEngine.classifyIntent('Ano ang magagawa mo? Help'),
        equals(AssistantIntent.generalHelp),
      );
    });

    test('6.1 Intent-to-SQL: Top Debtors returns accurate customer balances and bullets', () async {
      await db.recordDebt(
        customerName: 'Mang Kanor',
        totalAmount: 450.00,
        items: [],
      );
      await db.recordDebt(
        customerName: 'Aling Bebang',
        totalAmount: 920.00,
        items: [],
      );

      final resp = await engine.ask('Sino may utang?');
      expect(resp.intent, equals(AssistantIntent.topDebtors));
      expect(resp.bulletPoints.length, equals(2));
      expect(resp.bulletPoints.first, contains('Aling Bebang: ₱920.00')); // Sorted highest balance first
      expect(resp.answer, contains('1370.00'));
    });

    test('6.1 Intent-to-SQL: Low Stock returns products below safety threshold', () async {
      // Product 1: Stock 2 (Low stock!)
      await db.into(db.products).insert(
            const ProductsCompanion(
              id: drift.Value('p-egg'),
              name: drift.Value('Fresh Brown Egg'),
              category: drift.Value('Tingi'),
              costPrice: drift.Value(8.0),
              sellingPrice: drift.Value(10.0),
              currentStock: drift.Value(2.0),
              unit: drift.Value('pcs'),
            ),
          );

      // Product 2: Stock 50 (Sapat!)
      await db.into(db.products).insert(
            const ProductsCompanion(
              id: drift.Value('p-rice'),
              name: drift.Value('Sinandomeng Bigas 1kg'),
              category: drift.Value('Grains'),
              costPrice: drift.Value(45.0),
              sellingPrice: drift.Value(55.0),
              currentStock: drift.Value(50.0),
              unit: drift.Value('kg'),
            ),
          );

      final resp = await engine.ask('Kulang na stock');
      expect(resp.intent, equals(AssistantIntent.lowStock));
      expect(resp.bulletPoints.length, equals(1));
      expect(resp.bulletPoints.first, contains('Fresh Brown Egg: 2 pcs'));
    });

    test('6.1 Intent-to-SQL: Sales Summary calculates revenue and profit margin accurately', () async {
      await db.recordSale(
        paymentMethod: 'CASH',
        totalAmount: 100.0,
        amountReceived: 100.0,
        sukliAmount: 0.0,
        items: [
          const SaleItemsCompanion(
            id: drift.Value('s-1'),
            saleId: drift.Value(''),
            productId: drift.Value('p1'),
            productName: drift.Value('Item 1'),
            quantity: drift.Value(1.0),
            unitPrice: drift.Value(100.0),
            subtotal: drift.Value(100.0),
            profit: drift.Value(25.0),
          ),
        ],
      );

      final resp = await engine.ask('Benta ngayon');
      expect(resp.intent, equals(AssistantIntent.salesSummary));
      expect(resp.bulletPoints.any((b) => b.contains('Kabuuang Benta: ₱100.00')), isTrue);
      expect(resp.bulletPoints.any((b) => b.contains('Tinatayang Tubo: ₱25.00')), isTrue);
      expect(resp.bulletPoints.any((b) => b.contains('25.0% margin')), isTrue);
    });

    test('6.1 Intent-to-SQL: GCash Profit calculates fee earnings and transaction counts', () async {
      await db.recordGcash(
        transactionType: 'CASH_IN',
        amount: 1000.0,
        feeCharged: 15.0,
      );
      await db.recordGcash(
        transactionType: 'CASH_OUT',
        amount: 500.0,
        feeCharged: 10.0,
      );

      final resp = await engine.ask('Magkano kinita sa GCash?');
      expect(resp.intent, equals(AssistantIntent.gcashProfit));
      expect(resp.bulletPoints.first, contains('Kinita sa Service Fee: ₱25.00'));
      expect(resp.bulletPoints[1], contains('Cash-In Transaksyon: 1'));
      expect(resp.bulletPoints[2], contains('Cash-Out Transaksyon: 1'));
    });

    test('6.1 Intent-to-SQL: Supplier Payables lists upcoming bodega debts', () async {
      final dueDate = DateTime.now().add(const Duration(days: 2));
      await db.recordPayable(
        supplierName: 'Coca-Cola Sales Route',
        totalAmount: 3200.0,
        dueDate: dueDate,
        reminderNotes: 'Softdrinks Mismo 5 cases',
      );

      final resp = await engine.ask('May bayarin ba tayo sa bodega?');
      expect(resp.intent, equals(AssistantIntent.supplierPayables));
      expect(resp.bulletPoints.length, equals(1));
      expect(resp.bulletPoints.first, contains('Coca-Cola Sales Route: ₱3200.00'));
    });
  });
}
