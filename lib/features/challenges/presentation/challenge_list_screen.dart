import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/challenge_templates.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/calculations.dart';
import '../../../database/app_database.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/empty_state.dart';

class ChallengeListScreen extends ConsumerStatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  ConsumerState<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends ConsumerState<ChallengeListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'created'; // 'created', 'progress', 'target', 'date'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesStreamProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saving Challenges', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort By',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'created', child: Text('Recently Created')),
              const PopupMenuItem(value: 'progress', child: Text('Progress')),
              const PopupMenuItem(value: 'target', child: Text('Target Amount')),
              const PopupMenuItem(value: 'date', child: Text('End Date')),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search challenges...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // Main Tab Views
          Expanded(
            child: challengesAsync.when(
              data: (allChallenges) {
                final filtered = allChallenges.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery);
                }).toList();

                filtered.sort((a, b) {
                  switch (_sortBy) {
                    case 'target':
                      return b.targetAmount.compareTo(a.targetAmount);
                    case 'date':
                      return a.endDate.compareTo(b.endDate);
                    case 'created':
                    default:
                      return b.createdAt.compareTo(a.createdAt);
                  }
                });

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChallengeList(context, filtered.where((c) => c.status == 'active').toList(), currencySymbol),
                    _buildChallengeList(context, filtered.where((c) => c.status == 'completed').toList(), currencySymbol),
                    _buildChallengeList(context, filtered, currencySymbol),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/challenges/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChallengeList(BuildContext context, List<Challenge> challenges, String symbol) {
    if (challenges.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(
            icon: Icons.flag_outlined,
            title: 'No challenges found',
            message: 'Create a custom challenge or pick a recommended template below!',
            buttonLabel: '+ Custom Challenge',
            onButtonPressed: () => context.push('/challenges/create'),
          ),
          const SizedBox(height: 24),
          _buildRecommendedTemplatesSection(context),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...challenges.map((c) => _ChallengeTile(challenge: c)),
        const SizedBox(height: 24),
        _buildRecommendedTemplatesSection(context),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildRecommendedTemplatesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'Recommended Templates',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ChallengeTemplates.list.length,
            itemBuilder: (context, index) {
              final template = ChallengeTemplates.list[index];
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                child: AppCard(
                  onTap: () {
                    context.push(
                      '/challenges/create?name=${Uri.encodeComponent(template.name)}&target=${template.targetAmount}&freq=${template.frequency}&days=${template.durationDays}&desc=${Uri.encodeComponent(template.description)}',
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.flash_on, color: theme.colorScheme.primary, size: 20),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              template.frequency.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        template.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        template.description,
                        style: theme.textTheme.labelMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChallengeTile extends ConsumerWidget {
  final Challenge challenge;

  const _ChallengeTile({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final savingsAsync = ref.watch(savingsForChallengeStreamProvider(challenge.id));
    final theme = Theme.of(context);

    final isCompleted = challenge.status == 'completed';
    final isPaused = challenge.status == 'paused';

    return savingsAsync.when(
      data: (savings) {
        final totalSaved = SavingsCalculations.calculateTotalSaved(savings);
        final progress = SavingsCalculations.calculateProgress(challenge.targetAmount, totalSaved);
        final streak = SavingsCalculations.calculateStreak(savings, challenge.frequency);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: () => context.push('/challenges/${challenge.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('✓ COMPLETED', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else if (isPaused)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('PAUSED', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else if (streak > 0)
                      Text(
                        '🔥 $streak ${challenge.frequency}',
                        style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${CurrencyFormatter.format(totalSaved, symbol: currencySymbol)} saved of ${CurrencyFormatter.format(challenge.targetAmount, symbol: currencySymbol)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomProgressBar(progress: progress, height: 8),
              ],
            ),
          ),
        );
      },
      loading: () => Container(height: 80, margin: const EdgeInsets.only(bottom: 12), child: const AppCard(child: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => const SizedBox(),
    );
  }
}
