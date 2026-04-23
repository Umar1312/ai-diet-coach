import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:diet_coach_ai/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:diet_coach_ai/features/log_meal/camera_screen.dart';
import 'package:diet_coach_ai/features/log_meal/text_log_screen.dart';
import 'package:diet_coach_ai/presentation/screens/history/meal_history_screen.dart';
import 'package:diet_coach_ai/presentation/screens/profile/profile_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
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
        path: '/onboarding/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      // Main app
      GoRoute(
        path: '/home',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Meal logging
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/camera/menu',
        builder: (context, state) => const CameraScreen(isMenuMode: true),
      ),
      GoRoute(
        path: '/camera/confirm',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/camera/menu-results',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/log/text',
        builder: (context, state) => const TextLogScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const MealHistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
