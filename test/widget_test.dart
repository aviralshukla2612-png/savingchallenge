import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saving_challenge/app/app.dart';
import 'package:saving_challenge/core/constants/app_constants.dart';
import 'package:saving_challenge/core/services/ad_service.dart';
import 'package:saving_challenge/core/services/preferences_service.dart';
import 'package:saving_challenge/shared/providers/app_providers.dart';

void main() {
  testWidgets('App launches successfully to Welcome screen or Home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SavingChallengeApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Saving Challenge'), findsOneWidget);
  });

  test('Ad-Free 24h rewarded pass persists, extends, caps at 48h, and clears on reset', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = PreferencesService(prefs);

    expect(service.isAdFreeActive, isFalse);
    expect(service.adFreeRemaining, Duration.zero);

    final firstExpiry = await service.grantAdFreePass();
    expect(service.isAdFreeActive, isTrue);
    expect(service.adFreeRemaining.inHours, greaterThanOrEqualTo(23));
    expect(firstExpiry.isAfter(DateTime.now().add(const Duration(hours: 23))), isTrue);

    // Extending twice caps at 48 hours from now
    await service.grantAdFreePass();
    final cappedExpiry = await service.grantAdFreePass();
    expect(
      cappedExpiry.difference(DateTime.now()).inHours,
      lessThanOrEqualTo(48),
    );

    await service.clearAllSettings();
    expect(service.isAdFreeActive, isFalse);
  });

  test('AdService uses official Google test IDs in non-release mode and defines App Supporter badge', () {
    expect(AdService.bannerAdUnitId, 'ca-app-pub-3940256099942544/6300978111');
    expect(AdService.rewardedAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
    expect(
      AppAchievements.all.any((a) => a.key == 'ad_supporter'),
      isTrue,
    );
  });
}
