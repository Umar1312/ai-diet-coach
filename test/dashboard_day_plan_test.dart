import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/home_models.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

void main() {
  testWidgets('home summarizes every meal in today’s plan', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      dashboardStore.reset();
    });
    dashboardStore.applyPlan(_dayPlan());

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump();

    expect(find.text('Today’s plan'), findsOneWidget);
    expect(find.text('1 of 4 meals logged'), findsOneWidget);
    expect(find.text('Oats and berries'), findsOneWidget);
    expect(find.text('Paneer wrap'), findsOneWidget);
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(find.text('Dal rice'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('View all'), findsNothing);
    expect(find.text('No plan yet'), findsNothing);
    expect(find.text('Create plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

DailyPlan _dayPlan() => DailyPlan(
  dayId: '2026-09-03',
  userId: 'user-1',
  targets: const MacroTargets(
    calories: 2100,
    proteinG: 150,
    carbsG: 230,
    fatsG: 68,
  ),
  consumed: const MacroTargets(
    calories: 410,
    proteinG: 21,
    carbsG: 58,
    fatsG: 12,
  ),
  meals: const [],
  plannedMeals: const [
    PlannedMeal(
      slot: 'breakfast',
      order: 0,
      meal: Meal(
        name: 'Oats and berries',
        emoji: '🥣',
        calories: 410,
        proteinG: 21,
        carbsG: 58,
        fatsG: 12,
      ),
      status: PlannedMealStatus.logged,
    ),
    PlannedMeal(
      slot: 'lunch',
      order: 1,
      meal: Meal(
        name: 'Paneer wrap',
        emoji: '🌯',
        calories: 520,
        proteinG: 34,
        carbsG: 52,
        fatsG: 20,
      ),
      status: PlannedMealStatus.planned,
    ),
    PlannedMeal(
      slot: 'snack',
      order: 2,
      meal: Meal(
        name: 'Greek yogurt',
        emoji: '🥛',
        calories: 210,
        proteinG: 20,
        carbsG: 22,
        fatsG: 5,
      ),
      status: PlannedMealStatus.planned,
      isOptional: true,
    ),
    PlannedMeal(
      slot: 'dinner',
      order: 3,
      meal: Meal(
        name: 'Dal rice',
        emoji: '🍛',
        calories: 650,
        proteinG: 30,
        carbsG: 85,
        fatsG: 18,
      ),
      status: PlannedMealStatus.planned,
    ),
  ],
  dayStatus: DayStatus.onTrack,
  aiCardText: 'Your day is ready.',
  aiCardState: AICardState.onTrack,
  generatedAt: '2026-09-03T08:00:00Z',
);
