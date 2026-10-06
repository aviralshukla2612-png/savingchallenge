import 'package:flutter_test/flutter_test.dart';
import 'package:saving_challenge/core/utils/calculations.dart';
import 'package:saving_challenge/database/app_database.dart';

void main() {
  group('SavingsCalculations Unit Tests', () {
    test('calculateTotalSaved sums entry amounts correctly', () {
      final entries = [
        SavingEntry(id: 1, challengeId: 1, amount: 500.0, date: DateTime.now(), paymentMethod: 'upi', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        SavingEntry(id: 2, challengeId: 1, amount: 1500.0, date: DateTime.now(), paymentMethod: 'cash', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      final total = SavingsCalculations.calculateTotalSaved(entries);
      expect(total, equals(2000.0));
    });

    test('calculateRemaining clamps remaining amount to >= 0', () {
      expect(SavingsCalculations.calculateRemaining(10000, 4000), equals(6000.0));
      expect(SavingsCalculations.calculateRemaining(10000, 12000), equals(0.0));
    });

    test('calculateProgress clamps progress between 0.0 and 1.0', () {
      expect(SavingsCalculations.calculateProgress(10000, 5000), equals(0.5));
      expect(SavingsCalculations.calculateProgress(10000, 15000), equals(1.0));
      expect(SavingsCalculations.calculateProgress(10000, 0), equals(0.0));
    });

    test('calculateStreak daily streak calculation', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      final entries = [
        SavingEntry(id: 1, challengeId: 1, amount: 100, date: today, paymentMethod: 'cash', createdAt: now, updatedAt: now),
        SavingEntry(id: 2, challengeId: 1, amount: 100, date: yesterday, paymentMethod: 'cash', createdAt: now, updatedAt: now),
        SavingEntry(id: 3, challengeId: 1, amount: 100, date: dayBefore, paymentMethod: 'cash', createdAt: now, updatedAt: now),
      ];

      final streak = SavingsCalculations.calculateStreak(entries, 'daily');
      expect(streak, equals(3));
    });

    test('getReachedMilestones returns correct milestone thresholds', () {
      final milestones = SavingsCalculations.getReachedMilestones(10000, 5000);
      expect(milestones, containsAll([0.10, 0.25, 0.50]));
      expect(milestones, isNot(contains(0.75)));
    });
  });
}
