import 'package:drift/drift.dart';

@DataClassName('Challenge')
class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  RealColumn get targetAmount => real()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get frequency => text()(); // 'daily', 'weekly', 'monthly', 'custom'
  RealColumn get savingAmount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('active'))(); // 'active', 'completed', 'paused', 'cancelled'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
}
