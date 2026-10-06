import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

import '../../../database/app_database.dart';
import '../../../shared/providers/app_providers.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final double? initialTarget;
  final String? initialFrequency;
  final int? initialDurationDays;
  final String? initialDescription;

  const CreateChallengeScreen({
    super.key,
    this.initialName,
    this.initialTarget,
    this.initialFrequency,
    this.initialDurationDays,
    this.initialDescription,
  });

  @override
  ConsumerState<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _savingAmountController;
  late TextEditingController _descController;

  DateTime _startDate = DateTime.now();
  late DateTime _endDate;
  String _selectedFrequency = AppConstants.freqDaily;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _targetController = TextEditingController(text: widget.initialTarget != null ? widget.initialTarget.toString() : '');
    _descController = TextEditingController(text: widget.initialDescription ?? '');
    _savingAmountController = TextEditingController(text: '0');

    if (widget.initialFrequency != null && AppConstants.freqDaily != widget.initialFrequency) {
      _selectedFrequency = widget.initialFrequency!;
    }

    final duration = widget.initialDurationDays ?? 30;
    _endDate = DateTime.now().add(Duration(days: duration));

    _recalculateSuggestedSaving();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savingAmountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _recalculateSuggestedSaving() {
    final target = double.tryParse(_targetController.text.trim()) ?? 0.0;
    if (target <= 0) {
      _savingAmountController.text = '0';
      return;
    }

    final days = _endDate.difference(_startDate).inDays;
    if (days <= 0) {
      _savingAmountController.text = '0';
      return;
    }

    double suggested = 0.0;
    if (_selectedFrequency == AppConstants.freqWeekly) {
      final weeks = (days / 7).clamp(1.0, 520.0);
      suggested = target / weeks;
    } else if (_selectedFrequency == AppConstants.freqMonthly) {
      final months = (days / 30).clamp(1.0, 120.0);
      suggested = target / months;
    } else {
      suggested = target / days;
    }

    _savingAmountController.text = suggested > 0 ? suggested.toStringAsFixed(0) : '0';
  }


  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
        _recalculateSuggestedSaving();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final target = double.parse(_targetController.text.trim());
    final savingAmount = double.tryParse(_savingAmountController.text.trim()) ?? 0.0;
    final desc = _descController.text.trim();

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);

    try {
      await db.insertChallenge(
        ChallengesCompanion.insert(
          name: name,
          targetAmount: target,
          startDate: _startDate,
          endDate: _endDate,
          frequency: _selectedFrequency,
          savingAmount: drift.Value(savingAmount),
          description: drift.Value(desc.isEmpty ? null : desc),
          status: const drift.Value(AppConstants.statusActive),
        ),
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge "$name" created!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating challenge: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge Name
              Text('Challenge Name *', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. New Laptop, 52-Week Challenge...',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter challenge name';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Target Amount
              Text('Target Amount ($currencySymbol) *', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. 50000',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: theme.disabledColor.withValues(alpha: 0.35),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Text(currencySymbol, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                onChanged: (_) => _recalculateSuggestedSaving(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter target amount';
                  final n = double.tryParse(val.trim());
                  if (n == null || n <= 0) return 'Target amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Start & End Dates Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickDate(isStart: true),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
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
                        Text('End Date', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickDate(isStart: false),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.event)),
                            child: Text(DateFormat('dd MMM yyyy').format(_endDate)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Frequency
              Text('Saving Frequency', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedFrequency,
                items: const [
                  DropdownMenuItem(value: AppConstants.freqDaily, child: Text('Daily')),
                  DropdownMenuItem(value: AppConstants.freqWeekly, child: Text('Weekly')),
                  DropdownMenuItem(value: AppConstants.freqMonthly, child: Text('Monthly')),
                  DropdownMenuItem(value: AppConstants.freqCustom, child: Text('Custom')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFrequency = val;
                      _recalculateSuggestedSaving();
                    });
                  }
                },
                decoration: const InputDecoration(prefixIcon: Icon(Icons.repeat)),
              ),
              const SizedBox(height: 20),

              // Suggested/Saving Amount per period
              Text('Suggested Saving / Period ($currencySymbol)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _savingAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.savings),
                  hintText: 'e.g. 500',
                  helperText: 'Suggested saving per $_selectedFrequency interval',
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text('Description / Note (Optional)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Why are you saving for this goal?',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
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
                      : const Text('Start Challenge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
