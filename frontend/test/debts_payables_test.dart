import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:tindagrid/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 5: Bi-Directional Debt Tracker (Utang & Payables) Tests', () {
    test('5.1 Receivables: Can record customer debt with itemized list and track partial payment', () async {
      final dueDate = DateTime.now().add(const Duration(days: 7));

      final debtId = await db.recordDebt(
        customerName: 'Aling Marites',
        customerPhone: '09171234567',
        totalAmount: 385.00,
        dueDate: dueDate,
        notes: 'Bear Brand, Bigas 2kg, Itlog',
        items: [
          const DebtItemsCompanion(
            id: drift.Value('item-1'),
            debtId: drift.Value(''),
            description: drift.Value('Bear Brand 33g (x2)'),
            quantity: drift.Value(2.0),
            amount: drift.Value(30.00),
          ),
          const DebtItemsCompanion(
            id: drift.Value('item-2'),
            debtId: drift.Value(''),
            description: drift.Value('Bigas Dinorado 2kg'),
            quantity: drift.Value(2.0),
            amount: drift.Value(110.00),
          ),
          const DebtItemsCompanion(
            id: drift.Value('item-3'),
            debtId: drift.Value(''),
            description: drift.Value('Itlog Tray (x1)'),
            quantity: drift.Value(1.0),
            amount: drift.Value(245.00),
          ),
        ],
      );

      expect(debtId, isNotEmpty);

      // Verify customer debt saved
      final activeDebts = await (db.select(db.debts)..where((d) => d.id.equals(debtId))).getSingle();
      expect(activeDebts.customerName, equals('Aling Marites'));
      expect(activeDebts.customerPhone, equals('09171234567'));
      expect(activeDebts.remainingBalance, equals(385.00));
      expect(activeDebts.status, equals('PENDING'));

      // Verify itemized breakdown persisted
      final items = await db.getDebtItems(debtId);
      expect(items.length, equals(3));
      expect(items.first.description, contains('Bear Brand'));

      // Partial payment: customer pays ₱200
      await db.payDebt(debtId, 200.0);
      final afterPartial = await (db.select(db.debts)..where((d) => d.id.equals(debtId))).getSingle();
      expect(afterPartial.remainingBalance, equals(185.00));
      expect(afterPartial.status, equals('PARTIALLY_PAID'));

      // Full payment: customer pays remaining ₱185
      await db.payDebt(debtId, 185.0);
      final afterFull = await (db.select(db.debts)..where((d) => d.id.equals(debtId))).getSingle();
      expect(afterFull.remainingBalance, equals(0.0));
      expect(afterFull.status, equals('PAID'));

      // Sync queue has mutations queued
      final syncQueue = await db.getPendingSyncQueue();
      expect(syncQueue.any((q) => q.entityTable == 'debts' && q.entityId == debtId), isTrue);
    });

    test('5.2 Payables: Can record supplier payable, alert 48h due dates, and settle payment', () async {
      final urgentDue = DateTime.now().add(const Duration(hours: 24)); // Due in 24 hours (Urgent!)
      final regularDue = DateTime.now().add(const Duration(days: 10)); // Due in 10 days

      // 1. Record urgent delivery van debt (San Miguel delivery)
      final urgentPayableId = await db.recordPayable(
        supplierName: 'San Miguel Beer Delivery Van',
        contactNumber: '0918-999-8888',
        totalAmount: 4500.00,
        dueDate: urgentDue,
        reminderNotes: 'Pale Pilsen 2 cases, Red Horse 3 cases',
      );

      // 2. Record regular wholesale debt (Monde Nissin)
      await db.recordPayable(
        supplierName: 'Monde Nissin Bodega',
        contactNumber: '0922-111-2222',
        totalAmount: 2800.00,
        dueDate: regularDue,
        reminderNotes: 'Lucky Me Pancit Canton 5 boxes',
      );

      // 3. Test 48-Hour Urgent Watcher
      final urgentList = await db.watchPayablesDueSoon(threshold: const Duration(hours: 48)).first;
      expect(urgentList.length, equals(1));
      expect(urgentList.first.supplierName, contains('San Miguel'));
      expect(urgentList.first.totalAmount, equals(4500.00));

      // 4. Test Settle Payment to Delivery Van
      await db.paySupplier(urgentPayableId, 4500.00);

      final settledPayable = await (db.select(db.payables)..where((p) => p.id.equals(urgentPayableId))).getSingle();
      expect(settledPayable.paidAmount, equals(4500.00));
      expect(settledPayable.status, equals('SETTLED'));

      // Urgent watcher should now exclude settled debt
      final pendingUrgent = await db.watchPayablesDueSoon(threshold: const Duration(hours: 48)).first;
      expect(pendingUrgent.isEmpty, isTrue);

      // Sync queue has payables queued
      final syncQueue = await db.getPendingSyncQueue();
      expect(syncQueue.any((q) => q.entityTable == 'payables' && q.entityId == urgentPayableId), isTrue);
    });
  });
}
