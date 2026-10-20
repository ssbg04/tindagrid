import 'package:drift/drift.dart';

@DataClassName('GcashTransaction')
class GcashLedger extends Table {
  TextColumn get id => text()();
  // Transaction types: 'CASH_IN', 'CASH_OUT', 'STORE_PAYMENT'
  TextColumn get transactionType => text()();
  RealColumn get amount => real()();
  RealColumn get feeCharged => real().withDefault(const Constant(0.0))();
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GcashFeeBracket')
class GcashFeeConfig extends Table {
  TextColumn get id => text()();
  RealColumn get minAmount => real()();
  RealColumn get maxAmount => real()();
  RealColumn get fixedFee => real().withDefault(const Constant(0.0))();
  RealColumn get percentageFee => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}
