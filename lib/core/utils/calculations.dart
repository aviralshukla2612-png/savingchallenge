import 'dart:math';
import '../../database/app_database.dart';
import '../constants/app_constants.dart';

class SavingsCalculations {
  static double calculateTotalSaved(List<SavingEntry> entries) {
    return entries.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  static double calculateRemaining(double targetAmount, double totalSaved) {
    return max(0.0, targetAmount - totalSaved);
  }

  static double calculateProgress(double targetAmount, double totalSaved) {
    if (targetAmount <= 0) return 0.0;
    final progress = totalSaved / targetAmount;
    return progress.clamp(0.0, 1.0);
  }

  static int calculateStreak(List<SavingEntry> entries, String frequency) {
    if (entries.isEmpty) return 0;

    // Sort entries by date ascending
    final sorted = List<SavingEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (frequency == AppConstants.freqWeekly) {
      // Group entries by year-week number
      final weekKeys = <String>{};
      for (final e in sorted) {
        final weekNum = _getWeekNumber(e.date);
        weekKeys.add('${e.date.year}-W$weekNum');
      }

      final currentWeekKey = '${now.year}-W${_getWeekNumber(now)}';
      final prevWeek = now.subtract(const Duration(days: 7));
      final prevWeekKey = '${prevWeek.year}-W${_getWeekNumber(prevWeek)}';

      // Check if current or previous week is present
      if (!weekKeys.contains(currentWeekKey) && !weekKeys.contains(prevWeekKey)) {
        return 0;
      }

      var streak = 0;
      var checkDate = weekKeys.contains(currentWeekKey) ? now : prevWeek;

      while (true) {
        final key = '${checkDate.year}-W${_getWeekNumber(checkDate)}';
        if (weekKeys.contains(key)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 7));
        } else {
          break;
        }
      }
      return streak;
    } else if (frequency == AppConstants.freqMonthly) {
      // Group entries by YYYY-MM
      final monthKeys = <String>{};
      for (final e in sorted) {
        monthKeys.add('${e.date.year}-${e.date.month}');
      }

      final currentMonthKey = '${now.year}-${now.month}';
      final prevMonthDate = DateTime(now.year, now.month - 1, 1);
      final prevMonthKey = '${prevMonthDate.year}-${prevMonthDate.month}';

      if (!monthKeys.contains(currentMonthKey) && !monthKeys.contains(prevMonthKey)) {
        return 0;
      }

      var streak = 0;
      var checkYear = monthKeys.contains(currentMonthKey) ? now.year : prevMonthDate.year;
      var checkMonth = monthKeys.contains(currentMonthKey) ? now.month : prevMonthDate.month;

      while (true) {
        final key = '$checkYear-$checkMonth';
        if (monthKeys.contains(key)) {
          streak++;
          checkMonth--;
          if (checkMonth < 1) {
            checkMonth = 12;
            checkYear--;
          }
        } else {
          break;
        }
      }
      return streak;
    } else {
      // Daily & Custom frequency
      final dayKeys = <String>{};
      for (final e in sorted) {
        dayKeys.add('${e.date.year}-${e.date.month}-${e.date.day}');
      }

      final todayKey = '${today.year}-${today.month}-${today.day}';
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      if (!dayKeys.contains(todayKey) && !dayKeys.contains(yesterdayKey)) {
        return 0;
      }

      var streak = 0;
      var checkDate = dayKeys.contains(todayKey) ? today : yesterday;

      while (true) {
        final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
        if (dayKeys.contains(key)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    }
  }

  static double calculateAverageSaving(List<SavingEntry> entries) {
    if (entries.isEmpty) return 0.0;
    final total = calculateTotalSaved(entries);
    return total / entries.length;
  }

  static int calculateDaysRemaining(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = target.difference(today).inDays;
    return max(0, diff);
  }

  static String formatStreakLabel(int streak, String frequency) {
    if (frequency == AppConstants.freqWeekly) {
      return '$streak week${streak == 1 ? '' : 's'}';
    } else if (frequency == AppConstants.freqMonthly) {
      return '$streak month${streak == 1 ? '' : 's'}';
    } else {
      return '$streak day${streak == 1 ? '' : 's'}';
    }
  }

  static List<double> getReachedMilestones(double targetAmount, double totalSaved) {
    if (targetAmount <= 0) return [];
    final currentRatio = totalSaved / targetAmount;
    return AppConstants.milestones.where((m) => currentRatio >= m).toList();
  }

  static int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(date.difference(DateTime(date.year, 1, 1)).inDays.toString());
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
