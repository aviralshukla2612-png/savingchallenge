import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/calculations.dart';
import '../../../database/app_database.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../savings/presentation/add_saving_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final activeChallengesAsync = ref.watch(activeChallengesStreamProvider);
    final savingsAsync = ref.watch(savingEntriesStreamProvider);
    final challengesAsync = ref.watch(challengesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 36, borderRadius: 10),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${DateFormatter.getGreeting()} 👋',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Let's grow your savings.",
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            tooltip: 'About & Developer',
            onPressed: () => context.push('/settings/about'),
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, size: 22),
            tooltip: 'Privacy Policy',
            onPressed: () => context.push('/settings/privacy'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(challengesStreamProvider);
          ref.invalidate(savingEntriesStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Total Savings Card
              _buildTotalSavingsCard(context, ref, currencySymbol, savingsAsync),
              const SizedBox(height: 24),

              // 2. Active Challenges Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  activeChallengesAsync.when(
                    data: (list) => Text(
                      'Active Challenges (${list.length})',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    loading: () => Text('Active Challenges', style: theme.textTheme.titleLarge),
                    error: (err, stack) => Text('Active Challenges', style: theme.textTheme.titleLarge),
                  ),
                  TextButton(
                    onPressed: () => context.go('/challenges'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Active Challenges List / Cards
              activeChallengesAsync.when(
                data: (challenges) {
                  if (challenges.isEmpty) {
                    return AppCard(
                      child: EmptyState(
                        icon: Icons.savings_outlined,
                        title: 'No active challenges',
                        message: 'Start your first saving challenge and turn small savings into big goals.',
                        buttonLabel: '+ Create Challenge',
                        onButtonPressed: () => context.push('/challenges/create'),
                      ),
                    );
                  }
                  return Column(
                    children: challenges.map((challenge) {
                      return _ActiveChallengeCard(challenge: challenge);
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => AppCard(child: Text('Error: $err')),
              ),
              const SizedBox(height: 24),

              // 4. Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/savings/history'),
                    child: const Text('History'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              savingsAsync.when(
                data: (allSavings) {
                  if (allSavings.isEmpty) {
                    return AppCard(
                      child: EmptyState(
                        icon: Icons.history,
                        title: 'No savings recorded yet',
                        message: 'Record your first saving to start tracking progress.',
                        buttonLabel: '+ Add Saving',
                        onButtonPressed: () => AddSavingSheet.show(context),
                      ),
                    );
                  }
                  final recent = allSavings.take(5).toList();
                  final challengeList = challengesAsync.asData?.value ?? [];

                  return AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: recent.map((entry) {
                        final challenge = challengeList.firstWhere(
                          (c) => c.id == entry.challengeId,
                          orElse: () => Challenge(
                            id: 0,
                            name: 'Saving Challenge',
                            targetAmount: 0,
                            startDate: DateTime.now(),
                            endDate: DateTime.now(),
                            frequency: 'daily',
                            savingAmount: 0.0,
                            status: 'active',
                            createdAt: DateTime.now(),
                          ),
                        );
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.getPaymentMethodColor(entry.paymentMethod).withValues(alpha: 0.15),
                            child: Icon(
                              _getPaymentIcon(entry.paymentMethod),
                              color: AppColors.getPaymentMethodColor(entry.paymentMethod),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            CurrencyFormatter.format(entry.amount, symbol: currencySymbol),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${challenge.name} • ${entry.note ?? entry.paymentMethod.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            DateFormatter.formatRelativeDate(entry.date),
                            style: theme.textTheme.labelMedium,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                error: (err, _) => Text('Error: $err'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddSavingSheet.show(context),
        tooltip: 'Add Saving',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildTotalSavingsCard(
    BuildContext context,
    WidgetRef ref,
    String symbol,
    AsyncValue<List<SavingEntry>> savingsAsync,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return savingsAsync.when(
      data: (savings) {
        final totalSaved = SavingsCalculations.calculateTotalSaved(savings);
        final now = DateTime.now();
        final thisMonthSavings = savings.where((s) => s.date.year == now.year && s.date.month == now.month).toList();
        final thisMonthTotal = SavingsCalculations.calculateTotalSaved(thisMonthSavings);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.primaryDark, AppColors.surfaceDark]
                  : [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.primaryDark : AppColors.primary).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Saved',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Offline Saved',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                CurrencyFormatter.format(totalSaved, symbol: symbol),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${CurrencyFormatter.format(thisMonthTotal, symbol: symbol)} this month',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 140,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (err, stack) => const SizedBox(),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments;
      case 'bank':
        return Icons.account_balance;
      case 'upi':
        return Icons.qr_code;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

class _ActiveChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _ActiveChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final savingsAsync = ref.watch(savingsForChallengeStreamProvider(challenge.id));
    final theme = Theme.of(context);

    return savingsAsync.when(
      data: (savings) {
        final totalSaved = SavingsCalculations.calculateTotalSaved(savings);
        final remaining = SavingsCalculations.calculateRemaining(challenge.targetAmount, totalSaved);
        final progress = SavingsCalculations.calculateProgress(challenge.targetAmount, totalSaved);
        final streak = SavingsCalculations.calculateStreak(savings, challenge.frequency);
        final daysRemaining = SavingsCalculations.calculateDaysRemaining(challenge.endDate);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            onTap: () => context.push('/challenges/${challenge.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        challenge.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 12)),
                            Text(
                              SavingsCalculations.formatStreakLabel(streak, challenge.frequency),
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${CurrencyFormatter.format(totalSaved, symbol: currencySymbol)} / ${CurrencyFormatter.format(challenge.targetAmount, symbol: currencySymbol)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                CustomProgressBar(progress: progress, height: 10),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${CurrencyFormatter.format(remaining, symbol: currencySymbol)} remaining',
                        style: theme.textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$daysRemaining days left',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => AddSavingSheet.show(context, preselectedChallengeId: challenge.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Save',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              ],
            ),
          ),
        );
      },
      loading: () => Container(height: 120, margin: const EdgeInsets.only(bottom: 16), child: const AppCard(child: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => const SizedBox(),
    );
  }
}
