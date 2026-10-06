import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/challenges/presentation/challenge_list_screen.dart';
import '../features/challenges/presentation/challenge_detail_screen.dart';
import '../features/challenges/presentation/create_challenge_screen.dart';
import '../features/savings/presentation/saving_history_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/about_privacy_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../shared/providers/app_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final initialRoute = prefs.isOnboardingCompleted ? '/home' : '/welcome';

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/challenges',
            builder: (context, state) => const ChallengeListScreen(),
          ),
          GoRoute(
            path: '/statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/challenges/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uri = state.uri;
          final name = uri.queryParameters['name'];
          final target = double.tryParse(uri.queryParameters['target'] ?? '');
          final freq = uri.queryParameters['freq'];
          final days = int.tryParse(uri.queryParameters['days'] ?? '');
          final desc = uri.queryParameters['desc'];

          return CreateChallengeScreen(
            initialName: name,
            initialTarget: target,
            initialFrequency: freq,
            initialDurationDays: days,
            initialDescription: desc,
          );
        },
      ),
      GoRoute(
        path: '/challenges/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ChallengeDetailScreen(challengeId: id);
        },
      ),
      GoRoute(
        path: '/savings/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavingHistoryScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutPrivacyScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/challenges')) return 1;
    if (location.startsWith('/statistics')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/challenges');
        break;
      case 2:
        context.go('/statistics');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (int index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
