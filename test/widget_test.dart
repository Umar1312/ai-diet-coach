import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/core/router/app_router.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/presentation/screens/onboarding/plan_preview_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/pantry_intro_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/paywall_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/food_location_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/notification_permission_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/welcome_screen.dart';
import 'package:diet_coach_ai/presentation/widgets/onboarding_secondary_button.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/home_models.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/onboarding_state.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/shared/models/session_response.dart';
import 'package:diet_coach_ai/shared/models/user_setup_request.dart';
import 'package:diet_coach_ai/shared/widgets/glow_fab.dart';
import 'package:diet_coach_ai/stores/auth_store.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost');
  });

  testWidgets('welcome screen leads with the focused product promise', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(
      find.text('Meal plans that\nchange with\nyour day.'),
      findsOneWidget,
    );
    expect(find.text('Build my plan').hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Review the change. Keep what works.'),
      100,
    );
    expect(find.text('Turkey sandwich with salad'), findsOneWidget);
    expect(find.text('Build my plan').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focused paywall fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PaywallScreen()));

    expect(find.text('Know what to\neat next'), findsOneWidget);
    expect(find.text('View plans'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantry onboarding intro fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PantryIntroScreen()));

    expect(find.text('Meet your\nsmart pantry'), findsOneWidget);
    expect(find.text('Set up my pantry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification onboarding explains the value on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: NotificationPermissionScreen()),
    );

    expect(find.text('A small nudge,\nright when it helps.'), findsOneWidget);
    expect(find.text('Turn on meal check-ins'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Always in your control'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Always in your control'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first plan preview is useful on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(dashboardStore.reset);
    dashboardStore.applyPlan(_firstDayPlan());

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingPlanPreviewScreen(autoGenerate: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your first day,\nhandled.'), findsOneWidget);
    expect(find.text('YOUR DAILY TARGET'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Oats and berries'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Oats and berries'), findsOneWidget);
    expect(find.text('Looks good'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('food location onboarding fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: FoodLocationScreen()));

    expect(find.text('What food feels\nlike home?'), findsOneWidget);
    expect(find.text('Your favorites'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding skip actions stay centered at full width', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: OnboardingSecondaryButton(
              text: 'Skip for now',
              onPressed: null,
            ),
          ),
        ),
      ),
    );

    final buttonCenter = tester.getCenter(
      find.byType(OnboardingSecondaryButton),
    );
    final labelCenter = tester.getCenter(find.text('Skip for now'));
    expect(labelCenter.dx, buttonCenter.dx);
  });

  test('setup request sends canonical food preferences', () {
    const request = UserSetupRequest(
      gender: 'male',
      age: 28,
      heightCm: 175,
      weightKg: 78,
      activityLevel: 'moderate',
      goal: 'lose_weight',
      targetWeightKg: 72,
      dietaryRestrictions: [],
      country: 'IN',
      preferredCuisines: ['Mughlai', 'North Indian'],
    );

    expect(request.toJson()['country'], 'IN');
    expect(request.toJson()['preferred_cuisines'], ['Mughlai', 'North Indian']);
  });

  test('authenticated users can finish the paywall step', () {
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.authenticated,
        '/onboarding/paywall',
      ),
      isNull,
    );
    expect(
      AppRouter.redirectForAuthStatus(AuthStatus.authenticated, '/splash'),
      '/home',
    );
  });

  test('free users can navigate core app routes', () {
    expect(
      AppRouter.redirectForAuthStatus(AuthStatus.needsSubscription, '/home'),
      isNull,
    );
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsSubscription,
        '/onboarding/paywall',
      ),
      isNull,
    );
  });

  test('daily plan routes require Pro access', () {
    expect(AppRouter.redirectForProAccess(false), '/onboarding/paywall');
    expect(AppRouter.redirectForProAccess(true), isNull);
  });

  test('interrupted onboarding resumes at the persisted milestone', () {
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsOnboarding,
        '/splash',
        onboardingStage: OnboardingStage.profileSetup,
      ),
      '/onboarding/gender',
    );
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsOnboarding,
        '/splash',
        onboardingStage: OnboardingStage.pantrySetup,
      ),
      '/onboarding/pantry',
    );
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsOnboarding,
        '/home',
        onboardingStage: OnboardingStage.planPreview,
      ),
      '/onboarding/plan-preview',
    );
  });

  test('session parsing remains compatible with old backend responses', () {
    final legacyComplete = SessionResponse.fromJson({
      'uid': 'legacy-user',
      'profile_complete': true,
    });
    final legacyIncomplete = SessionResponse.fromJson({
      'uid': 'new-user',
      'profile_complete': false,
    });
    final staged = SessionResponse.fromJson({
      'uid': 'staged-user',
      'profile_complete': true,
      'onboarding_stage': 'pantry_setup',
    });
    final unknownStage = SessionResponse.fromJson({
      'uid': 'future-user',
      'profile_complete': true,
      'onboarding_stage': 'future_stage',
    });

    expect(legacyComplete.onboardingStage, OnboardingStage.complete);
    expect(legacyIncomplete.onboardingStage, OnboardingStage.profileSetup);
    expect(staged.onboardingStage, OnboardingStage.pantrySetup);
    expect(unknownStage.onboardingStage, OnboardingStage.profileSetup);
  });

  test('subscription status cannot bypass incomplete onboarding', () {
    expect(
      AuthStore.statusForOnboardingStage(
        OnboardingStage.planPreview,
        hasSubscriptionAccess: true,
      ),
      AuthStatus.needsOnboarding,
    );
    expect(
      AuthStore.statusForOnboardingStage(
        OnboardingStage.complete,
        hasSubscriptionAccess: false,
      ),
      AuthStatus.needsSubscription,
    );
  });

  test(
    'a created day plan supplies the next planned meal to the dashboard',
    () {
      final store = DashboardStore();
      store.applyPlan(
        DailyPlan(
          dayId: '2026-08-02',
          userId: 'test-user',
          targets: const MacroTargets(
            calories: 2000,
            proteinG: 150,
            carbsG: 220,
            fatsG: 65,
          ),
          consumed: const MacroTargets(
            calories: 0,
            proteinG: 0,
            carbsG: 0,
            fatsG: 0,
          ),
          meals: const [],
          plannedMeals: const [
            PlannedMeal(
              slot: 'lunch',
              order: 1,
              meal: Meal(
                name: 'Chicken salad',
                emoji: '🥗',
                calories: 480,
                proteinG: 42,
                carbsG: 24,
                fatsG: 18,
              ),
              status: PlannedMealStatus.planned,
            ),
            PlannedMeal(
              slot: 'breakfast',
              order: 0,
              meal: Meal(
                name: 'Oats and berries',
                emoji: '🥣',
                calories: 360,
                proteinG: 18,
                carbsG: 52,
                fatsG: 9,
              ),
              status: PlannedMealStatus.planned,
            ),
          ],
          dayStatus: DayStatus.onTrack,
          aiCardText: 'Ready for the day',
          aiCardState: AICardState.onTrack,
          generatedAt: '2026-08-02T08:00:00Z',
        ),
      );

      expect(store.plannedMeals, hasLength(2));
      expect(store.nextMeal.value?.name, 'Oats and berries');
      expect(store.nextMeal.value?.whyItFits, 'Your planned breakfast meal.');
    },
  );

  testWidgets('launch action menu does not expose camera logging', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlowFAB(onVoiceTap: () {}, onTextTap: () {}),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.camera_alt), findsNothing);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
  });
}

DailyPlan _firstDayPlan() {
  return DailyPlan(
    dayId: '2026-08-16',
    userId: 'preview-user',
    targets: const MacroTargets(
      calories: 2100,
      proteinG: 155,
      carbsG: 230,
      fatsG: 68,
    ),
    consumed: const MacroTargets(calories: 0, proteinG: 0, carbsG: 0, fatsG: 0),
    meals: const [],
    plannedMeals: const [
      PlannedMeal(
        slot: 'breakfast',
        order: 0,
        meal: Meal(
          name: 'Oats and berries',
          emoji: '🥣',
          prepMinutes: 8,
          calories: 390,
          proteinG: 21,
          carbsG: 56,
          fatsG: 10,
        ),
        status: PlannedMealStatus.planned,
      ),
      PlannedMeal(
        slot: 'lunch',
        order: 1,
        meal: Meal(
          name: 'Chicken power bowl',
          emoji: '🥗',
          prepMinutes: 20,
          calories: 560,
          proteinG: 48,
          carbsG: 54,
          fatsG: 18,
        ),
        status: PlannedMealStatus.planned,
      ),
    ],
    dayStatus: DayStatus.onTrack,
    aiCardText: 'Ready for the day',
    aiCardState: AICardState.onTrack,
    generatedAt: '2026-08-16T08:00:00Z',
  );
}
