import 'package:drift/drift.dart';

@DataClassName('Debt')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text().withLength(min: 1, max: 255)();
  TextColumn get customerPhone => text().nullable()();
  RealColumn get totalAmount => real()();
  RealColumn get remainingBalance => real()();
  DateTimeColumn get borrowedDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  // Status: 'PENDING', 'PARTIALLY_PAID', 'PAID'
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtItem')
class DebtItems extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get description => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get amount => real()();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
