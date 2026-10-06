import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:saving_challenge/database/app_database.dart';
import 'package:sqlite3/open.dart';
import 'dart:ffi';
import 'dart:io';

void main() {
  late AppDatabase db;

  setUpAll(() {
    if (Platform.isWindows) {
      try {
        open.overrideFor(OperatingSystem.windows, () {
          try {
            return DynamicLibrary.open('sqlite3.dll');
          } catch (_) {
            return DynamicLibrary.open('winsqlite3.dll');
          }
        });
      } catch (_) {}
    }
  });

  setUp(() {
    db = AppDatabase.forTesting(drift.DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() async {
    await db.close();
  });

  test('Database CRUD operations for challenges and saving entries', () async {
    final challengeId = await db.insertChallenge(
      ChallengesCompanion.insert(
        name: '52-Week Challenge',
        targetAmount: 52000,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        frequency: 'weekly',
      ),
    );

    expect(challengeId, equals(1));

    final challenge = await db.getChallengeById(challengeId);
    expect(challenge, isNotNull);
    expect(challenge!.name, equals('52-Week Challenge'));

    final entryId = await db.insertSaving(
      SavingEntriesCompanion.insert(
        challengeId: challengeId,
        amount: 1000,
        date: DateTime.now(),
        paymentMethod: const drift.Value('upi'),
      ),
    );

    expect(entryId, equals(1));

    final total = await db.getTotalSavedForChallenge(challengeId);
    expect(total, equals(1000.0));

    await db.deleteSavingData(entryId);
    final totalAfterDelete = await db.getTotalSavedForChallenge(challengeId);
    expect(totalAfterDelete, equals(0.0));
  });
}
