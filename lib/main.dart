import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobx/mobx.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/revenuecat_service.dart';
import 'core/services/meal_notification_service.dart';
import 'core/di/providers.dart';
import 'stores/auth_store.dart';
import 'stores/onboarding_store.dart';
import 'stores/dashboard_store.dart';
import 'stores/pantry_suggestions_store.dart';
import 'stores/profile_store.dart';
import 'features/log_meal/stores/text_log_store.dart';
import 'features/craving/stores/craving_store.dart';
import 'features/pantry/stores/pantry_store.dart';
import 'features/customize_day/stores/customize_day_store.dart';
import 'features/subscription/stores/subscription_store.dart';
import 'features/meal_check_in/stores/meal_check_in_store.dart';
import 'features/meal_swap/stores/meal_swap_store.dart';
import 'stores/notification_store.dart';

final revenueCatService = RevenueCatService();
final subscriptionStore = SubscriptionStore(
  revenueCatService: revenueCatService,
  apiService: apiService,
);
final authStore = AuthStore(subscriptionStore: subscriptionStore);
final onboardingStore = OnboardingStore();
final dashboardStore = DashboardStore();
final profileStore = ProfileStore(dashboardStore: dashboardStore);
final pantryStore = PantryStore(dashboardStore: dashboardStore);
final textLogStore = TextLogStore();
final pantrySuggestionsStore = PantrySuggestionsStore(pantryStore: pantryStore);
final cravingStore = CravingStore();
final customizeDayStore = CustomizeDayStore();
final mealNotificationService = MealNotificationService();
final notificationStore = NotificationStore(service: mealNotificationService);
final mealCheckInStore = MealCheckInStore(
  dashboardStore: dashboardStore,
  notificationStore: notificationStore,
);
final mealSwapStore = MealSwapStore(
  apiService: apiService,
  dashboardStore: dashboardStore,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  await subscriptionStore.initialize();
  await notificationStore.initialize();

  reaction<String>(
    (_) {
      final planState = dashboardStore.plannedMeals
          .map((meal) => '${meal.slot}:${meal.status.value}')
          .join('|');
      final timeState = notificationStore.times.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join('|');
      return '${authStore.status.value}:${notificationStore.enabled.value}:'
          '$timeState:$planState';
    },
    (_) {
      final status = authStore.status.value;
      final canSchedule =
          status == AuthStatus.authenticated ||
          status == AuthStatus.needsSubscription;
      unawaited(
        notificationStore.syncWithPlan(
          canSchedule ? dashboardStore.plannedMeals.toList() : const [],
        ),
      );
    },
    fireImmediately: true,
  );

  final useDevAuth = kDebugMode && AppConstants.devBearerToken.isNotEmpty;

  if (useDevAuth) {
    await authStore.setDevToken(AppConstants.devBearerToken);
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      authStore.init();
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      authStore.markUnauthenticated();
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ReactionDisposer _authReaction;

  @override
  void initState() {
    super.initState();
    notificationStore.onOpenCheckIn = _openPendingCheckIn;
    _authReaction = reaction<AuthStatus>(
      (_) => authStore.status.value,
      (_) => _openPendingCheckIn(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingCheckIn());
  }

  void _openPendingCheckIn() {
    final status = authStore.status.value;
    final canOpen =
        status == AuthStatus.authenticated ||
        status == AuthStatus.needsSubscription;
    if (!canOpen || notificationStore.pendingSlot.value == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final slot = notificationStore.takePendingSlot();
      if (slot == null) return;
      AppRouter.router.go(
        Uri(path: '/meal-check-in', queryParameters: {'slot': slot}).toString(),
      );
    });
  }

  @override
  void dispose() {
    notificationStore.onOpenCheckIn = null;
    _authReaction();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Diet Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
