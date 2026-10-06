import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/calculations.dart';

import '../../../database/app_database.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/milestone_dialog.dart';

class AddSavingSheet extends ConsumerStatefulWidget {
  final int? preselectedChallengeId;

  const AddSavingSheet({super.key, this.preselectedChallengeId});

  static Future<void> show(BuildContext context, {int? preselectedChallengeId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSavingSheet(preselectedChallengeId: preselectedChallengeId),
    );
  }

  @override
  ConsumerState<AddSavingSheet> createState() => _AddSavingSheetState();
}

class _AddSavingSheetState extends ConsumerState<AddSavingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _selectedChallengeId;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = AppConstants.payUpi;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedChallengeId = widget.preselectedChallengeId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChallengeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a saving challenge')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);

    try {
      final challengeId = _selectedChallengeId!;
      final challengeBefore = await db.getChallengeById(challengeId);
      final prevSavings = await db.getSavingsForChallenge(challengeId);
      final prevTotal = SavingsCalculations.calculateTotalSaved(prevSavings);

      await db.insertSaving(
        SavingEntriesCompanion.insert(
          challengeId: challengeId,
          amount: amount,
          date: _selectedDate,
          note: drift.Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
          paymentMethod: drift.Value(_selectedPaymentMethod),
        ),
      );

      // Check new totals & milestones
      final newSavings = await db.getSavingsForChallenge(challengeId);
      final newTotal = SavingsCalculations.calculateTotalSaved(newSavings);

      if (challengeBefore != null) {
        final target = challengeBefore.targetAmount;
        final prevProgress = prevTotal / target;
        final newProgress = newTotal / target;

        // Check completion
        if (newTotal >= target && challengeBefore.status == AppConstants.statusActive) {
          final updatedChallenge = challengeBefore.copyWith(
            status: AppConstants.statusCompleted,
            completedAt: drift.Value(DateTime.now()),
          );
          await db.updateChallengeData(updatedChallenge);
          await db.unlockAchievement('first_challenge', 'First Challenge', 'Completed your first saving challenge.');

          final allChallenges = await db.getAllChallenges();
          final completedCount = allChallenges.where((c) => c.status == AppConstants.statusCompleted).length;
          if (completedCount >= 5) {
            await db.unlockAchievement('savings_master', 'Savings Master', 'Completed 5 saving challenges.');
          }
        }

        // Check milestones
        int milestoneHit = 0;
        for (final m in [0.25, 0.50, 0.75, 1.00]) {
          if (prevProgress < m && newProgress >= m) {
            milestoneHit = (m * 100).toInt();
          }
        }

        // Check overall achievements
        await db.unlockAchievement('first_save', 'First Save', 'Made your first saving.');

        final overallTotal = await db.getAllSavings().then((list) => SavingsCalculations.calculateTotalSaved(list));
        if (overallTotal >= 1000) {
          await db.unlockAchievement('first_1000', 'First ₹1,000', 'Saved your first ₹1,000.');
        }
        if (overallTotal >= 10000) {
          await db.unlockAchievement('saved_10000', '₹10,000 Saved', 'Reached ₹10,000 total savings.');
        }
        if (overallTotal >= 50000) {
          await db.unlockAchievement('saved_50000', '₹50,000 Saved', 'Reached ₹50,000 total savings.');
        }

        if (mounted) {
          Navigator.of(context).pop();
          if (milestoneHit > 0) {
            MilestoneDialog.show(
              context,
              percentage: milestoneHit,
              challengeName: challengeBefore.name,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved ₹${amount.toStringAsFixed(0)} to ${challengeBefore.name}!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeChallengesAsync = ref.watch(activeChallengesStreamProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Record Saving',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Select Challenge Dropdown
                activeChallengesAsync.when(
                  data: (challenges) {
                    if (challenges.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No active challenges found. Create a challenge first!',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      );
                    }
                    if (_selectedChallengeId == null && challenges.isNotEmpty) {
                      _selectedChallengeId = challenges.first.id;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Challenge', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedChallengeId,
                          items: challenges.map((c) {
                            return DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedChallengeId = val),
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.flag)),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading challenges: $err'),
                ),
                const SizedBox(height: 16),

                // Saving Amount Input
                Text('Saving Amount ($currencySymbol)', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Text(
                        currencySymbol,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    hintText: 'e.g. 500',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: theme.disabledColor.withValues(alpha: 0.35),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter an amount';
                    final n = double.tryParse(val.trim());
                    if (n == null || n <= 0) return 'Amount must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker & Payment Method Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today, size: 20),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment Method', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPaymentMethod,
                            items: AppConstants.paymentMethods.map((pm) {
                              return DropdownMenuItem<String>(
                                value: pm,
                                child: Text(pm.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPaymentMethod = val);
                            },
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.account_balance_wallet, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Note
                Text('Note / Description (Optional)', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Skipped dining out, Weekly saving...',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
