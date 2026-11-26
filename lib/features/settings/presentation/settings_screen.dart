import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/utils/export_import_helper.dart';

import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/confirmation_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoadingRewardedAd = false;

  Future<void> _watchRewardedAdForAdFreePass() async {
    if (_isLoadingRewardedAd) return;
    setState(() => _isLoadingRewardedAd = true);

    final result = await AdService.showRewardedAd(
      onEarnedReward: (_) async {
        await ref.read(adFreePassProvider.notifier).grant24HourPass();
        final db = ref.read(databaseProvider);
        await db.unlockAchievement(
          'ad_supporter',
          'App Supporter',
          'Watched a rewarded video to support Saving Challenge.',
        );
        ref.invalidate(achievementsStreamProvider);
      },
    );

    if (!mounted) return;
    setState(() => _isLoadingRewardedAd = false);

    switch (result) {
      case RewardedAdResult.rewarded:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ad-Free Pass active for 24 hours! App Supporter badge unlocked.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case RewardedAdResult.dismissedWithoutReward:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Watch the full video to unlock the 24-hour Ad-Free Pass.',
            ),
          ),
        );
        break;
      case RewardedAdResult.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Rewarded video is unavailable right now. Check your internet connection and try again.',
            ),
          ),
        );
        break;
      case RewardedAdResult.unsupported:
        break;
    }
  }

  String _formatRemainingPass(DateTime until) {
    final diff = until.difference(DateTime.now());
    if (diff <= Duration.zero) return 'Expired';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    }
    return '${minutes.clamp(1, 59)}m remaining';
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final challenges = await db.getAllChallenges();
    final savings = await db.getAllSavings();
    final achievements = await db.getAllAchievements();

    final jsonStr = ExportImportHelper.exportToJson(
      challenges: challenges,
      savings: savings,
      achievements: achievements,
    );

    try {
      await Share.share(jsonStr, subject: 'Saving Challenge Backup (JSON)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final savings = await db.getAllSavings();
    final challenges = await db.getAllChallenges();

    final csvStr = ExportImportHelper.exportToCsv(savings, challenges);

    try {
      await Share.share(csvStr, subject: 'Saving Entries Export (CSV)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (context.mounted) {
        final confirm = await ConfirmationDialog.show(
          context,
          title: 'Import Backup?',
          message: 'Importing will merge backup data into your database. Continue?',
        );

        if (confirm == true) {
          try {
            final db = ref.read(databaseProvider);
            final count = await ExportImportHelper.importFromJson(content, db);
            ref.invalidate(challengesStreamProvider);
            ref.invalidate(savingEntriesStreamProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully imported $count challenges!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Import error: $e')),
              );
            }
          }
        }
      }
    }
  }

  Future<void> _resetApp(BuildContext context, WidgetRef ref) async {
    final confirm1 = await ConfirmationDialog.show(
      context,
      title: 'Reset Application?',
      message: 'This will permanently delete all your challenges, savings history, and achievements! This action CANNOT be undone.',
      confirmLabel: 'Reset Data',
      isDestructive: true,
    );

    if (confirm1 == true && context.mounted) {
      final confirm2 = await ConfirmationDialog.show(
        context,
        title: 'Final Confirmation',
        message: 'Are you 100% sure you want to clear all data?',
        confirmLabel: 'PERMANENTLY DELETE',
        isDestructive: true,
      );

      if (confirm2 == true && context.mounted) {
        final db = ref.read(databaseProvider);
        await db.clearAllData();
        final prefs = ref.read(preferencesServiceProvider);
        await prefs.clearAllSettings();
        ref.read(adFreePassProvider.notifier).refresh();

        ref.invalidate(challengesStreamProvider);
        ref.invalidate(savingEntriesStreamProvider);
        ref.invalidate(achievementsStreamProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application reset completely.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final adFreeUntil = ref.watch(adFreePassProvider);
    final isAdFreeActive =
        adFreeUntil != null && adFreeUntil.isAfter(DateTime.now());
    final currentCurrencyCode = prefs.currencyCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings Card
            Text('General', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.monetization_on),
                    title: const Text('Currency'),
                    trailing: DropdownButton<String>(
                      value: currentCurrencyCode,
                      underline: const SizedBox(),
                      items: AppConstants.currencies.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text('${e.value} ${e.key}'),
                        );
                      }).toList(),
                      onChanged: (code) {
                        if (code != null) {
                          final symbol = AppConstants.currencies[code] ?? '₹';
                          ref.read(currencySymbolProvider.notifier).updateCurrency(code, symbol);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('App Theme'),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (AdService.isSupported) ...[
              // Rewards & Ad-Free Pass Card (Opt-in Rewarded Ad)
              Text(
                'Rewards & Support',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: (isAdFreeActive
                            ? AppColors.success
                            : theme.colorScheme.primary)
                        .withValues(alpha: 0.14),
                    child: Icon(
                      isAdFreeActive
                          ? Icons.verified_rounded
                          : Icons.play_circle_fill_rounded,
                      color: isAdFreeActive
                          ? AppColors.success
                          : theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    isAdFreeActive
                        ? 'Ad-Free Pass Active'
                        : 'Remove Banner Ads (24h)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isAdFreeActive
                        ? 'Banner ads hidden • ${_formatRemainingPass(adFreeUntil)}. Watch another video to extend.'
                        : 'Watch a short video to hide banner ads for 24 hours & unlock the App Supporter badge.',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _isLoadingRewardedAd
                        ? null
                        : _watchRewardedAdForAdFreePass,
                    child: _isLoadingRewardedAd
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isAdFreeActive ? 'Extend' : 'Watch Ad'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Data Management Card
            Text('Data & Backup', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Export Backup (JSON)'),
                    subtitle: const Text('Save or share complete app data'),
                    onTap: () => _exportJson(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: const Text('Export History (CSV)'),
                    subtitle: const Text('Export transactions for Excel / Sheets'),
                    onTap: () => _exportCsv(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.download_for_offline),
                    title: const Text('Import Backup (JSON)'),
                    subtitle: const Text('Restore savings data from file'),
                    onTap: () => _importJson(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.danger),
                    title: const Text('Reset Application', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Delete all local data and reset app'),
                    onTap: () => _resetApp(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Card
            Text('About & Developer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.blue),
                    title: const Text('About Emperor Smart Solutions'),
                    subtitle: const Text('Social links, contact info, and company details'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/about'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: Colors.indigo),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our full data privacy policies'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.verified_user_rounded, color: Colors.amber),
                    title: Text('100% Offline & Private'),
                    subtitle: Text('No cloud servers, no account required. All financial data stays strictly on your device.'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code_rounded),
                    title: const Text('App Version'),
                    trailing: Text(AppConstants.appVersion, style: theme.textTheme.labelLarge),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2026 Emperor Smart Solutions. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
