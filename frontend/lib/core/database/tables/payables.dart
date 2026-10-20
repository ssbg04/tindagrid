import 'package:drift/drift.dart';

@DataClassName('Payable')
class Payables extends Table {
  TextColumn get id => text()();
  TextColumn get supplierName => text().withLength(min: 1, max: 255)();
  TextColumn get contactNumber => text().nullable()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get reminderNotes => text().nullable()();
  // Status: 'UNPAID', 'PARTIALLY_PAID', 'SETTLED'
  TextColumn get status => text().withDefault(const Constant('UNPAID'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
