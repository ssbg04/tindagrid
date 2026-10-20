import 'package:drift/drift.dart';

@DataClassName('Sale')
class Sales extends Table {
  TextColumn get id => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  // Payment methods: 'CASH', 'GCASH'
  TextColumn get paymentMethod => text().withDefault(const Constant('CASH'))();
  RealColumn get totalAmount => real()();
  RealColumn get amountReceived => real().withDefault(const Constant(0.0))();
  RealColumn get sukliAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalProfit => real().withDefault(const Constant(0.0))();
  BoolColumn get isDebt => boolean().withDefault(const Constant(false))();
  TextColumn get debtId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SaleItem')
class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get unitPrice => real()();
  RealColumn get subtotal => real()();
  RealColumn get profit => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}
