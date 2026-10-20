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

  group('Sync Engine & Change Tracker Tests', () {
    test('Saving product logs structured JSON mutation to sync_queue', () async {
      await db.saveProduct(
        ProductsCompanion.insert(
          id: 'prod-001',
          name: 'Silver Swan Soy Sauce 385ml',
          barcode: const Value('4800016644203'),
          category: const Value('Condiments'),
          costPrice: const Value(18.0),
          sellingPrice: const Value(22.0),
          currentStock: const Value(24.0),
        ),
      );

      final queue = await db.getPendingSyncQueue();
      expect(queue.length, 1);
      expect(queue.first.entityTable, 'products');
      expect(queue.first.entityId, 'prod-001');
      expect(queue.first.operation, 'UPSERT');
      expect(queue.first.payload, contains('Silver Swan Soy Sauce'));
      expect(queue.first.payload, contains('4800016644203'));

      // Test batch success marking
      await db.markSyncSuccessBatch([queue.first.id]);
      final pendingAfter = await db.getPendingSyncQueue();
      expect(pendingAfter.isEmpty, isTrue);
    });

    test('Sale transaction enqueues full sale and itemized breakdown for cloud sync', () async {
      // 1. Create a product
      await db.saveProduct(
        ProductsCompanion.insert(
          id: 'prod-coke',
          name: 'Coca-Cola 1.5L',
          barcode: const Value('4801981116111'),
          sellingPrice: const Value(75.0),
          currentStock: const Value(10.0),
        ),
      );

      // Clear the product save from sync queue
      final productQueue = await db.getPendingSyncQueue();
      await db.markSyncSuccessBatch(productQueue.map((e) => e.id).toList());

      // 2. Record sale
      final saleId = await db.recordSale(
        paymentMethod: 'CASH',
        totalAmount: 150.0,
        amountReceived: 200.0,
        sukliAmount: 50.0,
        items: [
          SaleItemsCompanion.insert(
            id: 'item-001',
            saleId: 'temp',
            productId: 'prod-coke',
            productName: 'Coca-Cola 1.5L',
            quantity: 2.0,
            unitPrice: 75.0,
            subtotal: 150.0,
          ),
        ],
      );

      final pendingSales = await db.getPendingSyncQueue();
      expect(pendingSales.length, 1);
      expect(pendingSales.first.entityTable, 'sales');
      expect(pendingSales.first.entityId, saleId);
      expect(pendingSales.first.payload, contains('"totalAmount":150.0'));
      expect(pendingSales.first.payload, contains('Coca-Cola 1.5L'));
    });

    test('Remote replication applies deltas and honors Last-Write-Wins', () async {
      final now = DateTime.now();

      // Remote product newer than empty local
      await db.applyRemoteProducts([
        {
          'id': 'remote-01',
          'barcode': '4800016644999',
          'name': 'Datu Puti Vinegar 385ml',
          'category': 'Condiments',
          'costPrice': 16.0,
          'sellingPrice': 20.0,
          'currentStock': 30,
          'unit': 'pcs',
          'isTingi': false,
          'updatedAt': now.toIso8601String(),
        }
      ]);

      final localProd = await db.getProductByBarcode('4800016644999');
      expect(localProd, isNotNull);
      expect(localProd!.name, 'Datu Puti Vinegar 385ml');
      expect(localProd.currentStock, 30.0);

      // Now apply an update from cloud with newer timestamp
      final later = now.add(const Duration(minutes: 5));
      await db.applyRemoteProducts([
        {
          'id': 'remote-01',
          'name': 'Datu Puti Vinegar 385ml (Updated)',
          'currentStock': 45,
          'updatedAt': later.toIso8601String(),
        }
      ]);

      final updatedProd = await db.getProductByBarcode('4800016644999');
      expect(updatedProd!.name, 'Datu Puti Vinegar 385ml (Updated)');
      expect(updatedProd.currentStock, 45.0);
    });

    test('Cloud Disaster Recovery restores complete snapshot', () async {
      await db.restoreCloudSnapshot(
        remoteProducts: [
          {
            'id': 'p-snap-1',
            'name': 'Lucky Me Pancit Canton Kalamansi',
            'barcode': '4807770270016',
            'sellingPrice': 15.0,
            'currentStock': 50,
          },
        ],
        remoteDebts: [
          {
            'id': 'd-snap-1',
            'customerName': 'Aling Nena',
            'totalAmount': 250.0,
            'remainingBalance': 150.0,
            'status': 'PARTIALLY_PAID',
          },
        ],
        remoteSales: [
          {
            'id': 's-snap-1',
            'totalAmount': 500.0,
            'paymentMethod': 'CASH',
          },
        ],
        remoteGcash: [
          {
            'id': 'g-snap-1',
            'type': 'CASH_IN',
            'amount': 1000.0,
            'feeCharged': 15.0,
          },
        ],
      );

      final products = await db.searchProducts('Lucky Me');
      expect(products.length, 1);
      expect(products.first.name, 'Lucky Me Pancit Canton Kalamansi');

      final debts = await db.watchActiveDebts().first;
      expect(debts.length, 1);
      expect(debts.first.customerName, 'Aling Nena');
      expect(debts.first.remainingBalance, 150.0);

      final gcash = await db.watchGcashTransactions().first;
      expect(gcash.length, 1);
      expect(gcash.first.amount, 1000.0);
      expect(gcash.first.feeCharged, 15.0);
    });
  });
}
