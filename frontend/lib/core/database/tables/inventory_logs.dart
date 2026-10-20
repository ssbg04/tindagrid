import 'package:drift/drift.dart';

@DataClassName('InventoryLog')
class InventoryLogs extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  RealColumn get changeQuantity => real()();
  RealColumn get previousStock => real()();
  RealColumn get newStock => real()();
  // Reasons: 'restock', 'sale', 'damage', 'audit', 'tingi_repack'
  TextColumn get reason => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
