import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saving_challenge/app/app.dart';
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
}
