import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyCurrencyCode = 'currency_code';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyAppPinHash = 'app_pin_hash';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String keyReminderHour = 'reminder_hour';
  static const String keyReminderMinute = 'reminder_minute';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Currency
  String get currencyCode => _prefs.getString(keyCurrencyCode) ?? 'INR';
  String get currencySymbol => _prefs.getString(keyCurrencySymbol) ?? '₹';

  Future<void> setCurrency(String code, String symbol) async {
    await _prefs.setString(keyCurrencyCode, code);
    await _prefs.setString(keyCurrencySymbol, symbol);
  }

  // Theme Mode: 'system', 'light', 'dark'
  String get themeMode => _prefs.getString(keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(keyThemeMode, mode);
  }

  // Onboarding
  bool get isOnboardingCompleted => _prefs.getBool(keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(keyOnboardingCompleted, value);
  }

  // App PIN Security
  bool get isPinSet => _prefs.containsKey(keyAppPinHash) && (_prefs.getString(keyAppPinHash)?.isNotEmpty ?? false);

  String hashPin(String pin) {
    return sha256.convert(utf8.encode('saving_challenge_salt_$pin')).toString();
  }

  Future<bool> setPin(String pin) async {
    return await _prefs.setString(keyAppPinHash, hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final savedHash = _prefs.getString(keyAppPinHash);
    if (savedHash == null) return false;
    return savedHash == hashPin(pin);
  }

  Future<void> removePin() async {
    await _prefs.remove(keyAppPinHash);
    await setBiometricEnabled(false);
  }

  // Biometrics
  bool get isBiometricEnabled => _prefs.getBool(keyBiometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(keyBiometricEnabled, enabled);
  }

  // Reminders
  bool get isDailyReminderEnabled => _prefs.getBool(keyDailyReminderEnabled) ?? false;
  int get reminderHour => _prefs.getInt(keyReminderHour) ?? 20; // 8:00 PM default
  int get reminderMinute => _prefs.getInt(keyReminderMinute) ?? 0;

  Future<void> setDailyReminder(bool enabled, {int hour = 20, int minute = 0}) async {
    await _prefs.setBool(keyDailyReminderEnabled, enabled);
    await _prefs.setInt(keyReminderHour, hour);
    await _prefs.setInt(keyReminderMinute, minute);
  }

  Future<void> clearAllSettings() async {
    await _prefs.clear();
  }
}
