import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/calculations.dart';

import '../../../database/app_database.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/stat_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final savingsAsync = ref.watch(savingEntriesStreamProvider);
    final challengesAsync = ref.watch(challengesStreamProvider);
    final achievementsAsync = ref.watch(achievementsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: savingsAsync.when(
        data: (allSavings) {
          final challenges = challengesAsync.asData?.value ?? [];
          final activeCount = challenges.where((c) => c.status == AppConstants.statusActive).length;
          final completedCount = challenges.where((c) => c.status == AppConstants.statusCompleted).length;

          final totalSaved = SavingsCalculations.calculateTotalSaved(allSavings);

          final now = DateTime.now();
          final thisMonthSavings = allSavings.where((s) => s.date.year == now.year && s.date.month == now.month).toList();
          final thisMonthTotal = SavingsCalculations.calculateTotalSaved(thisMonthSavings);

          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final thisWeekSavings = allSavings.where((s) => s.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
          final thisWeekTotal = SavingsCalculations.calculateTotalSaved(thisWeekSavings);

          final avgSaving = SavingsCalculations.calculateAverageSaving(allSavings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Overview Metric Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    StatCard(
                      title: 'Total Saved',
                      value: CurrencyFormatter.format(totalSaved, symbol: currencySymbol),
                      icon: Icons.account_balance_wallet,
                      iconColor: AppColors.primary,
                    ),
                    StatCard(
                      title: 'This Month',
                      value: CurrencyFormatter.format(thisMonthTotal, symbol: currencySymbol),
                      icon: Icons.calendar_month,
                      iconColor: Colors.blue,
                    ),
                    StatCard(
                      title: 'This Week',
                      value: CurrencyFormatter.format(thisWeekTotal, symbol: currencySymbol),
                      icon: Icons.date_range,
                      iconColor: Colors.purple,
                    ),
                    StatCard(
                      title: 'Average Saving',
                      value: CurrencyFormatter.format(avgSaving, symbol: currencySymbol),
                      icon: Icons.show_chart,
                      iconColor: Colors.orange,
                    ),
                    StatCard(
                      title: 'Active Challenges',
                      value: '$activeCount',
                      icon: Icons.flag,
                      iconColor: Colors.teal,
                    ),
                    StatCard(
                      title: 'Completed',
                      value: '$completedCount',
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Monthly Savings Chart
                Text('Monthly Savings Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 200,
                    child: _buildMonthlyBarChart(allSavings, currencySymbol, theme),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Payment Method Breakdown Pie Chart
                Text('Payment Method Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 200,
                    child: _buildPaymentPieChart(allSavings, currencySymbol, theme),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Achievements Section
                Text('Badges & Achievements', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                achievementsAsync.when(
                  data: (unlockedList) {
                    final unlockedKeys = unlockedList.map((a) => a.achievementKey).toSet();
                    return Column(
                      children: AppAchievements.all.map((def) {
                        final isUnlocked = unlockedKeys.contains(def.key);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isUnlocked ? Colors.amber.withValues(alpha: 0.2) : theme.disabledColor.withValues(alpha: 0.1),
                                child: Icon(
                                  isUnlocked ? Icons.emoji_events : Icons.lock,
                                  color: isUnlocked ? Colors.amber.shade700 : theme.disabledColor,
                                ),
                              ),
                              title: Text(
                                def.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? theme.textTheme.titleLarge?.color : theme.disabledColor,
                                ),
                              ),
                              subtitle: Text(def.description),
                              trailing: isUnlocked
                                  ? const Text('UNLOCKED 🎉', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold))
                                  : const Text('LOCKED', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const SizedBox(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<SavingEntry> savings, String symbol, ThemeData theme) {
    if (savings.isEmpty) {
      return const Center(child: Text('No saving records available for chart'));
    }

    final now = DateTime.now();
    final monthlyData = <int, double>{};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = m.month;
      monthlyData[key] = 0.0;
    }

    for (final s in savings) {
      if (monthlyData.containsKey(s.date.month)) {
        monthlyData[s.date.month] = (monthlyData[s.date.month] ?? 0) + s.amount;
      }
    }

    final entries = monthlyData.entries.toList();
    final maxY = entries.fold(1.0, (max, e) => e.value > max ? e.value : max);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                final monthNum = entries[idx].key;
                final monthName = DateFormat('MMM').format(DateTime(2026, monthNum, 1));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(monthName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (index) {
          final val = entries[index].value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: theme.colorScheme.primary,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPaymentPieChart(List<SavingEntry> savings, String symbol, ThemeData theme) {
    if (savings.isEmpty) {
      return const Center(child: Text('No saving records available for chart'));
    }

    final totals = <String, double>{};
    for (final s in savings) {
      totals[s.paymentMethod] = (totals[s.paymentMethod] ?? 0.0) + s.amount;
    }

    final overall = totals.values.fold(0.0, (sum, v) => sum + v);
    if (overall <= 0) return const Center(child: Text('No data'));

    final sections = totals.entries.map((e) {
      final pct = (e.value / overall * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: e.value,
        title: '${e.key.toUpperCase()}\n$pct%',
        color: AppColors.getPaymentMethodColor(e.key),
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 4,
      ),
    );
  }
}
