import 'package:drift/drift.dart';

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  TextColumn get id => text()();
  // Table name: 'products', 'sales', 'debts', 'inventory_logs', etc.
  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();
  // Operation: 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get operation => text()();
  // JSON payload of the mutation
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // Status: 'PENDING', 'SYNCING', 'FAILED', 'COMPLETED'
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
