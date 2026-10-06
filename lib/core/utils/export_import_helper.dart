import 'dart:convert';
import 'package:csv/csv.dart';
import '../../database/app_database.dart';
import 'package:drift/drift.dart';

class ExportImportHelper {
  static String exportToJson({
    required List<Challenge> challenges,
    required List<SavingEntry> savings,
    required List<Achievement> achievements,
  }) {
    final Map<String, dynamic> data = {
      'app': 'Saving Challenge',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'challenges': challenges.map((c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'targetAmount': c.targetAmount,
        'startDate': c.startDate.toIso8601String(),
        'endDate': c.endDate.toIso8601String(),
        'frequency': c.frequency,
        'savingAmount': c.savingAmount,
        'status': c.status,
        'createdAt': c.createdAt.toIso8601String(),
        'completedAt': c.completedAt?.toIso8601String(),
        'pausedAt': c.pausedAt?.toIso8601String(),
      }).toList(),
      'savingEntries': savings.map((s) => {
        'id': s.id,
        'challengeId': s.challengeId,
        'amount': s.amount,
        'date': s.date.toIso8601String(),
        'note': s.note,
        'paymentMethod': s.paymentMethod,
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
      }).toList(),
      'achievements': achievements.map((a) => {
        'id': a.id,
        'achievementKey': a.achievementKey,
        'title': a.title,
        'description': a.description,
        'unlockedAt': a.unlockedAt.toIso8601String(),
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static String exportToCsv(List<SavingEntry> savings, List<Challenge> challenges) {
    final challengeMap = {for (final c in challenges) c.id: c.name};

    final List<List<dynamic>> rows = [
      ['ID', 'Challenge Name', 'Amount', 'Date', 'Payment Method', 'Note'],
    ];

    for (final s in savings) {
      rows.add([
        s.id,
        challengeMap[s.challengeId] ?? 'Unknown Challenge',
        s.amount,
        s.date.toIso8601String().split('T').first,
        s.paymentMethod,
        s.note ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static Future<int> importFromJson(String jsonContent, AppDatabase db) async {
    final Map<String, dynamic> decoded = jsonDecode(jsonContent);

    if (decoded['app'] != 'Saving Challenge' || !decoded.containsKey('challenges')) {
      throw FormatException('Invalid backup file format.');
    }

    final challengesList = decoded['challenges'] as List<dynamic>? ?? [];
    final savingsList = decoded['savingEntries'] as List<dynamic>? ?? [];
    final achievementsList = decoded['achievements'] as List<dynamic>? ?? [];

    int importedChallenges = 0;

    await db.transaction(() async {
      for (final raw in challengesList) {
        final item = Map<String, dynamic>.from(raw as Map);
        await db.into(db.challenges).insertOnConflictUpdate(
          ChallengesCompanion(
            id: Value(item['id'] as int),
            name: Value(item['name'] as String),
            description: Value(item['description'] as String?),
            targetAmount: Value((item['targetAmount'] as num).toDouble()),
            startDate: Value(DateTime.parse(item['startDate'] as String)),
            endDate: Value(DateTime.parse(item['endDate'] as String)),
            frequency: Value(item['frequency'] as String),
            savingAmount: Value((item['savingAmount'] as num? ?? 0.0).toDouble()),
            status: Value(item['status'] as String? ?? 'active'),
            createdAt: Value(DateTime.parse(item['createdAt'] as String)),
            completedAt: Value(item['completedAt'] != null ? DateTime.parse(item['completedAt'] as String) : null),
            pausedAt: Value(item['pausedAt'] != null ? DateTime.parse(item['pausedAt'] as String) : null),
          ),
        );
        importedChallenges++;
      }

      for (final raw in savingsList) {
        final item = Map<String, dynamic>.from(raw as Map);
        await db.into(db.savingEntries).insertOnConflictUpdate(
          SavingEntriesCompanion(
            id: Value(item['id'] as int),
            challengeId: Value(item['challengeId'] as int),
            amount: Value((item['amount'] as num).toDouble()),
            date: Value(DateTime.parse(item['date'] as String)),
            note: Value(item['note'] as String?),
            paymentMethod: Value(item['paymentMethod'] as String? ?? 'cash'),
            createdAt: Value(DateTime.parse(item['createdAt'] as String)),
            updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
          ),
        );
      }

      for (final raw in achievementsList) {
        final item = Map<String, dynamic>.from(raw as Map);
        await db.into(db.achievements).insertOnConflictUpdate(
          AchievementsCompanion(
            id: Value(item['id'] as int),
            achievementKey: Value(item['achievementKey'] as String),
            title: Value(item['title'] as String),
            description: Value(item['description'] as String),
            unlockedAt: Value(DateTime.parse(item['unlockedAt'] as String)),
          ),
        );
      }
    });

    return importedChallenges;
  }
}
