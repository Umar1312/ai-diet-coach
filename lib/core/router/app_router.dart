import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/features/auth/login_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/welcome_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/gender_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/age_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/height_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/weight_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/activity_level_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/goal_selection_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/target_weight_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/dietary_restrictions_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/calc_result_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/loading_setup_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/notification_permission_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/paywall_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/pantry_intro_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/food_location_screen.dart';
import 'package:diet_coach_ai/presentation/screens/splash/splash_screen.dart';

import 'package:diet_coach_ai/presentation/screens/home/home_shell.dart';
import 'package:diet_coach_ai/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:diet_coach_ai/presentation/screens/pantry/pantry_screen.dart';
import 'package:diet_coach_ai/presentation/screens/plan/plan_screen.dart';
import 'package:diet_coach_ai/presentation/screens/profile/profile_screen.dart';
import 'package:diet_coach_ai/features/customize_day/customize_day_screen.dart';

import 'package:diet_coach_ai/features/log_meal/text_log_screen.dart';
import 'package:diet_coach_ai/presentation/screens/history/meal_history_screen.dart';
import 'package:diet_coach_ai/presentation/screens/pantry/pantry_suggestions_screen.dart';
import 'package:diet_coach_ai/presentation/screens/pantry/pantry_onboarding_screen.dart';

import 'package:diet_coach_ai/main.dart';
import 'package:diet_coach_ai/stores/auth_store.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _homeNavKey = GlobalKey<NavigatorState>();
  static final _pantryNavKey = GlobalKey<NavigatorState>();
  static final _planNavKey = GlobalKey<NavigatorState>();
  static final _profileNavKey = GlobalKey<NavigatorState>();

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshNotifier(),
    redirect: (context, state) {
      final status = authStore.status.value;
      final location = state.matchedLocation;
      final isSplashRoute = location == '/splash';
      final isLoginRoute = location == '/login';
      final isWelcomeRoute = location == '/';
      final isOnboardingFlow = location.startsWith('/onboarding');

      // While auth state is unknown, keep the neutral splash on screen.
      if (status == AuthStatus.unknown) {
        return isSplashRoute ? null : '/splash';
      }

      // Unauthenticated -> force to login (unless already there).
      if (status == AuthStatus.unauthenticated) {
        return isLoginRoute ? null : '/login';
      }

      // Authenticated but onboarding incomplete -> allow onboarding flow +
      // welcome; block main app + login.
      if (status == AuthStatus.needsOnboarding) {
        if (isOnboardingFlow || isWelcomeRoute) return null;
        return '/';
      }

      if (status == AuthStatus.needsSubscription) {
        if (isOnboardingFlow) return null;
        return '/onboarding/paywall';
      }

      // Fully authenticated -> block login + welcome only. Allow /onboarding/*
      // so the user can finish the post-setup flow (pantry, paywall, etc.).
      if (status == AuthStatus.authenticated &&
          (isLoginRoute ||
              isSplashRoute ||
              isWelcomeRoute ||
              location == '/onboarding/paywall')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // Onboarding
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/onboarding/gender',
        builder: (context, state) => const GenderScreen(),
      ),
      GoRoute(
        path: '/onboarding/age',
        builder: (context, state) => const AgeScreen(),
      ),
      GoRoute(
        path: '/onboarding/height',
        builder: (context, state) => const HeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/weight',
        builder: (context, state) => const WeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/activity',
        builder: (context, state) => const ActivityLevelScreen(),
      ),
      GoRoute(
        path: '/onboarding/goal',
        builder: (context, state) => const GoalSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/target-weight',
        builder: (context, state) => const TargetWeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/restrictions',
        builder: (context, state) => const DietaryRestrictionsScreen(),
      ),
      GoRoute(
        path: '/onboarding/food-location',
        builder: (context, state) => const FoodLocationScreen(),
      ),
      GoRoute(
        path: '/onboarding/result',
        builder: (context, state) => const CalcResultScreen(),
      ),
      GoRoute(
        path: '/onboarding/loading',
        builder: (context, state) => const LoadingSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        builder: (context, state) => const NotificationPermissionScreen(),
      ),
      GoRoute(
        path: '/onboarding/pantry',
        builder: (context, state) => const PantryIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),

      // Main app — persistent 4-tab shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _pantryNavKey,
            routes: [
              GoRoute(
                path: '/pantry',
                builder: (context, state) => const PantryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _planNavKey,
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => const PlanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Meal logging (outside shell, push on top)
      GoRoute(
        path: '/log/text',
        builder: (context, state) => const TextLogScreen(),
      ),
      GoRoute(
        path: '/plan/customize',
        builder: (context, state) => const CustomizeDayScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const MealHistoryScreen(),
      ),
      GoRoute(
        path: '/pantry/suggestions',
        builder: (context, state) => const PantrySuggestionsScreen(),
      ),
      GoRoute(
        path: '/pantry/onboarding',
        builder: (context, state) => PantryOnboardingScreen(
          isOnboarding: state.uri.queryParameters['source'] == 'onboarding',
        ),
      ),
    ],
  );

  static GoRouter get router => _router;
}

/// Bridges MobX observable [AuthStore.status] to go_router's
/// [refreshListenable] so the redirect runs whenever auth state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    reaction((_) => authStore.status.value, (_) => notifyListeners());
  }
}
