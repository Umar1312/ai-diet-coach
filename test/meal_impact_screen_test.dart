import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/features/meal_impact/meal_impact_screen.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/home_models.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/meal_log_item.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

void main() {
  testWidgets('shows a calm receipt when the day needs no changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = DashboardStore()
      ..applyMealLogResponse(_logResponse(withAdjustment: false));

    await tester.pumpWidget(MaterialApp(home: MealImpactScreen(store: store)));

    expect(find.text('MEAL LOGGED'), findsOneWidget);
    expect(find.text('You’re still\non track.'), findsOneWidget);
    expect(find.text('Office paneer wrap'), findsOneWidget);
    expect(find.text('Back to today'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No changes needed'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No changes needed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('makes an off-plan adjustment easy to understand', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = DashboardStore()
      ..applyMealLogResponse(_logResponse(withAdjustment: true));

    await tester.pumpWidget(MaterialApp(home: MealImpactScreen(store: store)));

    expect(find.text('Your day can\nstill work.'), findsOneWidget);
    expect(find.text('Update my day'), findsOneWidget);
    expect(find.text('Try another adjustment'), findsOneWidget);
    expect(find.text('Keep my original plan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Suggested adjustment'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('🍝 Creamy chicken pasta'), findsOneWidget);
    expect(find.text('🥗 Grilled chicken salad'), findsOneWidget);
    expect(find.text('Nothing changes until you approve it.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('meal log responses preserve the item used by the impact flow', () {
    final store = DashboardStore();
    final response = _logResponse(withAdjustment: false);

    store.applyMealLogResponse(response);

    expect(store.lastLoggedMeal.value?.id, response.log.id);
    expect(store.consumedCalories.value, 720);
  });
}

MealLogResponse _logResponse({required bool withAdjustment}) {
  const currentDinner = PlannedMeal(
    slot: 'dinner',
    order: 3,
    meal: Meal(
      name: 'Creamy chicken pasta',
      emoji: '🍝',
      calories: 720,
      proteinG: 38,
      carbsG: 82,
      fatsG: 26,
    ),
    status: PlannedMealStatus.planned,
  );
  const suggestedDinner = PlannedMeal(
    slot: 'dinner',
    order: 3,
    meal: Meal(
      name: 'Grilled chicken salad',
      emoji: '🥗',
      calories: 480,
      proteinG: 46,
      carbsG: 28,
      fatsG: 18,
    ),
    status: PlannedMealStatus.planned,
  );
  final logged = MealLogItem(
    id: 'log-1',
    userId: 'user-1',
    dayId: '2026-09-03',
    source: 'text',
    loggedAt: DateTime(2026, 9, 3, 13),
    meal: const Meal(
      name: 'Office paneer wrap',
      emoji: '🌯',
      calories: 720,
      proteinG: 31,
      carbsG: 78,
      fatsG: 29,
    ),
  );
  return MealLogResponse(
    log: logged,
    updatedPlan: DailyPlan(
      dayId: '2026-09-03',
      userId: 'user-1',
      targets: const MacroTargets(
        calories: 2100,
        proteinG: 150,
        carbsG: 230,
        fatsG: 68,
      ),
      consumed: const MacroTargets(
        calories: 720,
        proteinG: 31,
        carbsG: 78,
        fatsG: 29,
      ),
      meals: [logged],
      plannedMeals: const [currentDinner],
      pendingProposal: withAdjustment
          ? const ProposedPlan(
              changedSlots: [suggestedDinner],
              reason:
                  'A lighter, higher-protein dinner keeps the rest of today realistic.',
            )
          : null,
      dayStatus: DayStatus.onTrack,
      aiCardText: 'You are still in a workable range.',
      aiCardState: AICardState.onTrack,
      generatedAt: '2026-09-03T13:00:00Z',
    ),
  );
}
