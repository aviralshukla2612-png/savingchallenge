import 'package:drift/drift.dart';
import 'connection/connection.dart' as conn;

import 'tables/challenges_table.dart';
import 'tables/saving_entries_table.dart';
import 'tables/achievements_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Challenges, SavingEntries, Achievements])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.openConnection());

  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  // --- Challenge Operations ---
  Future<List<Challenge>> getAllChallenges() => select(challenges).get();

  Stream<List<Challenge>> watchAllChallenges() => select(challenges).watch();

  Stream<List<Challenge>> watchActiveChallenges() {
    return (select(challenges)..where((tbl) => tbl.status.equals('active'))).watch();
  }

  Stream<List<Challenge>> watchCompletedChallenges() {
    return (select(challenges)..where((tbl) => tbl.status.equals('completed'))).watch();
  }

  Future<Challenge?> getChallengeById(int id) {
    return (select(challenges)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Stream<Challenge?> watchChallengeById(int id) {
    return (select(challenges)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  Future<int> insertChallenge(ChallengesCompanion companion) => into(challenges).insert(companion);

  Future<bool> updateChallengeData(Challenge challenge) => update(challenges).replace(challenge);

  Future<int> deleteChallengeData(int id) {
    return (delete(challenges)..where((tbl) => tbl.id.equals(id))).go();
  }

  // --- Saving Entries Operations ---
  Future<List<SavingEntry>> getAllSavings() => select(savingEntries).get();

  Stream<List<SavingEntry>> watchAllSavings() {
    return (select(savingEntries)..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])).watch();
  }

  Future<List<SavingEntry>> getSavingsForChallenge(int challengeId) {
    return (select(savingEntries)
          ..where((tbl) => tbl.challengeId.equals(challengeId))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<SavingEntry>> watchSavingsForChallenge(int challengeId) {
    return (select(savingEntries)
          ..where((tbl) => tbl.challengeId.equals(challengeId))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> insertSaving(SavingEntriesCompanion companion) => into(savingEntries).insert(companion);

  Future<bool> updateSavingData(SavingEntry entry) => update(savingEntries).replace(entry);

  Future<int> deleteSavingData(int id) {
    return (delete(savingEntries)..where((tbl) => tbl.id.equals(id))).go();
  }

  // --- Calculations derived from source-of-truth ---
  Future<double> getTotalSavedForChallenge(int challengeId) async {
    final query = selectOnly(savingEntries)
      ..addColumns([savingEntries.amount.sum()])
      ..where(savingEntries.challengeId.equals(challengeId));
    final result = await query.getSingle();
    return result.read(savingEntries.amount.sum()) ?? 0.0;
  }

  Stream<double> watchTotalSavedForChallenge(int challengeId) {
    final query = selectOnly(savingEntries)
      ..addColumns([savingEntries.amount.sum()])
      ..where(savingEntries.challengeId.equals(challengeId));
    return query.watchSingle().map((row) => row.read(savingEntries.amount.sum()) ?? 0.0);
  }

  Stream<double> watchTotalSavedOverall() {
    final query = selectOnly(savingEntries)..addColumns([savingEntries.amount.sum()]);
    return query.watchSingle().map((row) => row.read(savingEntries.amount.sum()) ?? 0.0);
  }

  // --- Achievement Operations ---
  Future<List<Achievement>> getAllAchievements() => select(achievements).get();
  Stream<List<Achievement>> watchAllAchievements() => select(achievements).watch();

  Future<int> unlockAchievement(String key, String title, String description) async {
    final existing = await (select(achievements)..where((tbl) => tbl.achievementKey.equals(key))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(achievements).insert(
      AchievementsCompanion.insert(
        achievementKey: key,
        title: title,
        description: description,
        unlockedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearAllData() async {
    await delete(savingEntries).go();
    await delete(challenges).go();
    await delete(achievements).go();
  }
}



