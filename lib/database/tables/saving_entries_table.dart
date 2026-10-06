import 'package:drift/drift.dart';
import 'challenges_table.dart';

@DataClassName('SavingEntry')
class SavingEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get challengeId => integer().references(Challenges, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))(); // 'cash', 'bank', 'upi', 'card', 'other'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
