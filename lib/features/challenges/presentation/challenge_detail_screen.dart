import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/calculations.dart';
import '../../../database/app_database.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../savings/presentation/add_saving_sheet.dart';
import '../../savings/presentation/edit_saving_sheet.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final int challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  Future<void> _togglePause(BuildContext context, WidgetRef ref, Challenge challenge) async {
    final db = ref.read(databaseProvider);
    final isPaused = challenge.status == AppConstants.statusPaused;
    final newStatus = isPaused ? AppConstants.statusActive : AppConstants.statusPaused;

    final updated = challenge.copyWith(
      status: newStatus,
      pausedAt: isPaused ? const drift.Value.absent() : drift.Value(DateTime.now()),
    );

    await db.updateChallengeData(updated);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isPaused ? 'Challenge Resumed!' : 'Challenge Paused!')),
      );
    }
  }

  Future<void> _deleteChallenge(BuildContext context, WidgetRef ref, Challenge challenge) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Challenge?',
      message: 'Are you sure you want to delete "${challenge.name}"? All related saving entries will also be permanently deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteChallengeData(challenge.id);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge "${challenge.name}" deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);

    return StreamBuilder<Challenge?>(
      stream: db.watchChallengeById(challengeId),
      builder: (context, snapshot) {
        final challenge = snapshot.data;
        if (challenge == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Challenge not found')),
          );
        }

        final savingsAsync = ref.watch(savingsForChallengeStreamProvider(challengeId));

        return Scaffold(
          appBar: AppBar(
            title: Text(challenge.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(challenge.status == AppConstants.statusPaused ? Icons.play_arrow : Icons.pause),
                tooltip: challenge.status == AppConstants.statusPaused ? 'Resume Challenge' : 'Pause Challenge',
                onPressed: () => _togglePause(context, ref, challenge),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete') {
                    _deleteChallenge(context, ref, challenge);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.danger, size: 20),
                        SizedBox(width: 8),
                        Text('Delete Challenge', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: savingsAsync.when(
            data: (savings) {
              final totalSaved = SavingsCalculations.calculateTotalSaved(savings);
              final remaining = SavingsCalculations.calculateRemaining(challenge.targetAmount, totalSaved);
              final progress = SavingsCalculations.calculateProgress(challenge.targetAmount, totalSaved);
              final streak = SavingsCalculations.calculateStreak(savings, challenge.frequency);
              final avgSaving = SavingsCalculations.calculateAverageSaving(savings);
              final daysRemaining = SavingsCalculations.calculateDaysRemaining(challenge.endDate);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner if Paused or Completed
                    if (challenge.status == AppConstants.statusPaused) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pause_circle_filled, color: Colors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Challenge Paused on ${challenge.pausedAt != null ? DateFormat('dd MMM').format(challenge.pausedAt!) : ''}. Progress is preserved.',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Primary Progress Card
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            CurrencyFormatter.format(totalSaved, symbol: currencySymbol),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'saved of ${CurrencyFormatter.format(challenge.targetAmount, symbol: currencySymbol)}',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),

                          CustomProgressBar(progress: progress, height: 14, showPercentage: true),
                          const SizedBox(height: 20),

                          PrimaryButton(
                            label: '+ Record Saving',
                            icon: Icons.add,
                            onPressed: () => AddSavingSheet.show(context, preselectedChallengeId: challenge.id),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        StatCard(
                          title: 'Remaining',
                          value: CurrencyFormatter.format(remaining, symbol: currencySymbol),
                          icon: Icons.hourglass_bottom,
                          iconColor: Colors.amber.shade700,
                        ),
                        StatCard(
                          title: 'Current Streak',
                          value: '🔥 $streak',
                          subtitle: challenge.frequency,
                          icon: Icons.whatshot,
                          iconColor: Colors.deepOrange,
                        ),
                        StatCard(
                          title: 'Average Saving',
                          value: CurrencyFormatter.format(avgSaving, symbol: currencySymbol),
                          icon: Icons.bar_chart,
                          iconColor: Colors.blue,
                        ),
                        StatCard(
                          title: 'Days Left',
                          value: '$daysRemaining days',
                          icon: Icons.timer,
                          iconColor: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Milestones Timeline
                    Text('Milestones', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [10, 25, 50, 75, 90, 100].map((pct) {
                            final isReached = (progress * 100) >= pct;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  Icon(
                                    isReached ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isReached ? AppColors.success : theme.disabledColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),


                    // Saving History for this Challenge
                    Text('Saving History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (savings.isEmpty)
                      const AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No savings added for this challenge yet.'),
                          ),
                        ),
                      )
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: savings.map((entry) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.getPaymentMethodColor(entry.paymentMethod).withValues(alpha: 0.15),
                                child: Icon(
                                  _getPaymentIcon(entry.paymentMethod),
                                  color: AppColors.getPaymentMethodColor(entry.paymentMethod),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                CurrencyFormatter.format(entry.amount, symbol: currencySymbol),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${DateFormatter.formatDate(entry.date)} • ${entry.note ?? entry.paymentMethod.toUpperCase()}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => EditSavingSheet.show(context, entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: AppColors.danger),
                                    onPressed: () async {
                                      final confirm = await ConfirmationDialog.show(
                                        context,
                                        title: 'Delete Saving?',
                                        message: 'Are you sure you want to delete ${CurrencyFormatter.format(entry.amount, symbol: currencySymbol)}?',
                                        isDestructive: true,
                                      );
                                      if (confirm == true) {
                                        await db.deleteSavingData(entry.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        );
      },
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
