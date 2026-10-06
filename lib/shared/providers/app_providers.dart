import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/app_database.dart';
import '../../core/services/preferences_service.dart';

// Database Singleton Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// SharedPreferences Instance Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in ProviderScope overrides');
});

// Preferences Service Provider
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

// Settings Notifiers
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesService _prefs;

  ThemeModeNotifier(this._prefs) : super(_parseTheme(_prefs.themeMode));

  static ThemeMode _parseTheme(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _prefs.setThemeMode(modeStr);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ThemeModeNotifier(prefs);
});

class CurrencyNotifier extends StateNotifier<String> {
  final PreferencesService _prefs;

  CurrencyNotifier(this._prefs) : super(_prefs.currencySymbol);

  Future<void> updateCurrency(String code, String symbol) async {
    await _prefs.setCurrency(code, symbol);
    state = symbol;
  }
}

final currencySymbolProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return CurrencyNotifier(prefs);
});

final currencyCodeProvider = Provider<String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return prefs.currencyCode;
});

// Database Reactive Streams
final challengesStreamProvider = StreamProvider<List<Challenge>>((ref) {
  return ref.watch(databaseProvider).watchAllChallenges();
});

final activeChallengesStreamProvider = StreamProvider<List<Challenge>>((ref) {
  return ref.watch(databaseProvider).watchActiveChallenges();
});

final completedChallengesStreamProvider = StreamProvider<List<Challenge>>((ref) {
  return ref.watch(databaseProvider).watchCompletedChallenges();
});

final savingEntriesStreamProvider = StreamProvider<List<SavingEntry>>((ref) {
  return ref.watch(databaseProvider).watchAllSavings();
});

final savingsForChallengeStreamProvider = StreamProvider.family<List<SavingEntry>, int>((ref, challengeId) {
  return ref.watch(databaseProvider).watchSavingsForChallenge(challengeId);
});

final totalSavedOverallStreamProvider = StreamProvider<double>((ref) {
  return ref.watch(databaseProvider).watchTotalSavedOverall();
});

final achievementsStreamProvider = StreamProvider<List<Achievement>>((ref) {
  return ref.watch(databaseProvider).watchAllAchievements();
});
