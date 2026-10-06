import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import 'add_saving_sheet.dart';
import 'edit_saving_sheet.dart';

class SavingHistoryScreen extends ConsumerStatefulWidget {
  const SavingHistoryScreen({super.key});

  @override
  ConsumerState<SavingHistoryScreen> createState() => _SavingHistoryScreenState();
}

class _SavingHistoryScreenState extends ConsumerState<SavingHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPaymentFilter = 'all';
  String _sortBy = 'newest'; // 'newest', 'oldest', 'highest', 'lowest'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savingsAsync = ref.watch(savingEntriesStreamProvider);
    final challengesAsync = ref.watch(challengesStreamProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final db = ref.watch(databaseProvider);

    final challengeMap = <int, String>{};
    if (challengesAsync.hasValue) {
      for (final c in challengesAsync.value!) {
        challengeMap[c.id] = c.name;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saving History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Options',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Text('Newest First')),
              const PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
              const PopupMenuItem(value: 'highest', child: Text('Highest Amount')),
              const PopupMenuItem(value: 'lowest', child: Text('Lowest Amount')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by note or challenge...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Methods'),
                        selected: _selectedPaymentFilter == 'all',
                        onSelected: (_) => setState(() => _selectedPaymentFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      ...AppConstants.paymentMethods.map((pm) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(pm.toUpperCase()),
                            selected: _selectedPaymentFilter == pm,
                            onSelected: (_) => setState(() => _selectedPaymentFilter = pm),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Savings List
          Expanded(
            child: savingsAsync.when(
              data: (allSavings) {
                var filtered = allSavings.where((s) {
                  final cName = (challengeMap[s.challengeId] ?? '').toLowerCase();
                  final note = (s.note ?? '').toLowerCase();
                  final matchesSearch = cName.contains(_searchQuery) || note.contains(_searchQuery);
                  final matchesMethod = _selectedPaymentFilter == 'all' || s.paymentMethod == _selectedPaymentFilter;
                  return matchesSearch && matchesMethod;
                }).toList();

                // Sort
                if (_sortBy == 'newest') {
                  filtered.sort((a, b) => b.date.compareTo(a.date));
                } else if (_sortBy == 'oldest') {
                  filtered.sort((a, b) => a.date.compareTo(b.date));
                } else if (_sortBy == 'highest') {
                  filtered.sort((a, b) => b.amount.compareTo(a.amount));
                } else if (_sortBy == 'lowest') {
                  filtered.sort((a, b) => a.amount.compareTo(b.amount));
                }

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.history_toggle_off,
                    title: 'No savings found',
                    message: 'No saving records match your search query or filters.',
                    buttonLabel: '+ Add Saving',
                    onButtonPressed: () => AddSavingSheet.show(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final challengeName = challengeMap[entry.challengeId] ?? 'Saving Challenge';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
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
                            '$challengeName • ${DateFormatter.formatDate(entry.date)}\n${entry.note ?? 'No note'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => EditSavingSheet.show(context, entry),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: AppColors.danger),
                                onPressed: () async {
                                  final confirm = await ConfirmationDialog.show(
                                    context,
                                    title: 'Delete Saving Entry?',
                                    message: 'Are you sure you want to delete ${CurrencyFormatter.format(entry.amount, symbol: currencySymbol)}? Progress will be recalculated.',
                                    isDestructive: true,
                                  );
                                  if (confirm == true) {
                                    await db.deleteSavingData(entry.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddSavingSheet.show(context),
        child: const Icon(Icons.add),
      ),
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
