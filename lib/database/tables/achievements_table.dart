import 'package:drift/drift.dart';

@DataClassName('Achievement')
class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get achievementKey => text().customConstraint('UNIQUE NOT NULL')();
  TextColumn get title => text()();
  TextColumn get description => text()();
  DateTimeColumn get unlockedAt => dateTime()();
}
