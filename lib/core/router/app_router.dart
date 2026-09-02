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
import 'package:diet_coach_ai/presentation/screens/onboarding/plan_preview_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/food_location_screen.dart';
import 'package:diet_coach_ai/presentation/screens/splash/splash_screen.dart';

import 'package:diet_coach_ai/presentation/screens/home/home_shell.dart';
import 'package:diet_coach_ai/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:diet_coach_ai/presentation/screens/pantry/pantry_screen.dart';
import 'package:diet_coach_ai/presentation/screens/plan/plan_screen.dart';
import 'package:diet_coach_ai/presentation/screens/profile/profile_screen.dart';

import 'package:diet_coach_ai/features/log_meal/text_log_screen.dart';
import 'package:diet_coach_ai/features/meal_impact/meal_impact_screen.dart';
import 'package:diet_coach_ai/features/customize_day/customize_day_screen.dart';
import 'package:diet_coach_ai/features/meal_check_in/meal_check_in_screen.dart';
import 'package:diet_coach_ai/presentation/screens/history/meal_history_screen.dart';
import 'package:diet_coach_ai/presentation/screens/pantry/pantry_onboarding_screen.dart';
import 'package:diet_coach_ai/presentation/screens/profile/notification_settings_screen.dart';

import 'package:diet_coach_ai/main.dart';
import 'package:diet_coach_ai/shared/models/onboarding_state.dart';
import 'package:diet_coach_ai/stores/auth_store.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _homeNavKey = GlobalKey<NavigatorState>();
  static final _pantryNavKey = GlobalKey<NavigatorState>();
  static final _planNavKey = GlobalKey<NavigatorState>();

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshNotifier(),
    redirect: (context, state) => redirectForAuthStatus(
      authStore.status.value,
      state.matchedLocation,
      onboardingStage: authStore.onboardingStage.value,
      isOnboardingPantryPicker:
          state.matchedLocation == '/pantry/onboarding' &&
          state.uri.queryParameters['source'] == 'onboarding',
    ),
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
        path: '/onboarding/plan-preview',
        builder: (context, state) => const OnboardingPlanPreviewScreen(),
      ),
      GoRoute(
        path: '/onboarding/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),

      // Main app — persistent 3-tab shell
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
        ],
      ),

      // Meal logging (outside shell, push on top)
      GoRoute(
        path: '/log/text',
        builder: (context, state) => const TextLogScreen(),
      ),
      GoRoute(
        path: '/meal-check-in',
        builder: (context, state) =>
            MealCheckInScreen(slot: state.uri.queryParameters['slot'] ?? ''),
      ),
      GoRoute(
        path: '/meal-impact',
        builder: (context, state) => const MealImpactScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const MealHistoryScreen(),
      ),
      GoRoute(
        path: '/plan/customize',
        redirect: (context, state) =>
            subscriptionStore.hasAccess.value ? null : '/onboarding/paywall',
        builder: (context, state) => const CustomizeDayScreen(),
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

  static String? redirectForAuthStatus(
    AuthStatus status,
    String location, {
    OnboardingStage onboardingStage = OnboardingStage.profileSetup,
    bool isOnboardingPantryPicker = false,
  }) {
    final isSplashRoute = location == '/splash';
    final isLoginRoute = location == '/login';
    final isWelcomeRoute = location == '/';
    final isOnboardingFlow =
        location.startsWith('/onboarding') || location == '/pantry/onboarding';
    final isPantrySetupRoute =
        location == '/onboarding/pantry' || isOnboardingPantryPicker;

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
      final resumePath = switch (onboardingStage) {
        OnboardingStage.profileSetup => '/',
        OnboardingStage.pantrySetup => '/onboarding/pantry',
        OnboardingStage.planPreview => '/onboarding/plan-preview',
        OnboardingStage.complete => '/home',
      };
      if (isPantrySetupRoute &&
          onboardingStage != OnboardingStage.pantrySetup) {
        return resumePath;
      }
      if (isSplashRoute || isLoginRoute) return resumePath;
      if (isWelcomeRoute && onboardingStage != OnboardingStage.profileSetup) {
        return resumePath;
      }
      if (isOnboardingFlow || isWelcomeRoute) return null;
      return resumePath;
    }

    // The onboarding starter-pack endpoint is stage-gated. A completed user
    // may still use the regular pantry picker, but must never reopen its
    // onboarding variant from stale navigation state or a deep link.
    if (isPantrySetupRoute) return '/home';

    if (status == AuthStatus.needsSubscription) {
      // Free users can use the core app. Premium navigation is individually
      // gated (for example, the daily plan route) using the entitlement.
      if (isLoginRoute || isSplashRoute || isWelcomeRoute) return '/home';
      return null;
    }

    // Fully authenticated -> block login, splash, and welcome. Keep
    // onboarding routes available so the post-setup flow can finish cleanly.
    if (status == AuthStatus.authenticated &&
        (isLoginRoute || isSplashRoute || isWelcomeRoute)) {
      return '/home';
    }

    return null;
  }
}

/// Bridges MobX observable [AuthStore.status] to go_router's
/// [refreshListenable] so the redirect runs whenever auth state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    reaction(
      (_) => (authStore.status.value, authStore.onboardingStage.value),
      (_) => notifyListeners(),
    );
  }
}
