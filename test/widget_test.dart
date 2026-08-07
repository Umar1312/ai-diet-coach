import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/core/router/app_router.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/pantry_intro_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/paywall_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/food_location_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/welcome_screen.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/home_models.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
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

    expect(find.text('Stop wondering\nwhat to eat next'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Build my plan'), 200);
    expect(find.text('Build my plan'), findsOneWidget);
    expect(find.text('Thank you for\ntrusting us'), findsNothing);
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

  testWidgets('food location onboarding fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: FoodLocationScreen()));

    expect(find.text('What food feels\nlike home?'), findsOneWidget);
    expect(find.text('Your favorites'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  test('subscription-required users are held at the paywall', () {
    expect(
      AppRouter.redirectForAuthStatus(AuthStatus.needsSubscription, '/home'),
      '/onboarding/paywall',
    );
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsSubscription,
        '/onboarding/paywall',
      ),
      isNull,
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
