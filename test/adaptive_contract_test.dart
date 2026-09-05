import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

void main() {
  test('shared adaptive plan fixture preserves identity and protection', () {
    final json =
        jsonDecode(File('test/fixtures/adaptive_plan.json').readAsStringSync())
            as Map<String, dynamic>;

    final plan = DailyPlan.fromJson(json);

    expect(plan.id, 'plan-2026-09-05');
    expect(plan.revision, 13);
    expect(plan.adaptationStatus, AdaptationStatus.proposalReady);
    expect(plan.adaptationAccess.remaining, 2);
    expect(plan.plannedMeals.single.id, 'dinner-slot');
    expect(plan.plannedMeals.single.isProtected, isTrue);
    expect(plan.plannedMeals.single.meal.servings, 1.5);
    expect(plan.plannedMeals.single.meal.ingredients.single.name, 'Lentils');
    expect(plan.pendingProposal?.sourcePlanRevision, 13);
  });

  test('meal log mutation sends explicit day, revision, intent and basis', () {
    const meal = Meal(
      name: 'Paneer wrap',
      emoji: '🌯',
      calories: 540,
      proteinG: 36,
      carbsG: 63,
      fatsG: 17,
      servings: 1.5,
      servingUnit: 'wrap',
      nutritionBasis: NutritionBasis(
        servingAmount: 1,
        servingUnit: 'wrap',
        calories: 360,
        proteinG: 24,
        carbsG: 42,
        fatsG: 11,
      ),
    );
    const request = MealLogMutationRequest(
      operationId: 'operation-1',
      dayId: '2026-09-05',
      expectedPlanRevision: 12,
      intent: MealLogIntent.replacement,
      slotId: 'lunch-slot',
      source: 'text',
      meal: meal,
    );

    final json = request.toJson();

    expect(json['day_id'], '2026-09-05');
    expect(json['expected_plan_revision'], 12);
    expect(json['intent'], 'replacement');
    expect(json['slot_id'], 'lunch-slot');
    expect((json['meal'] as Map)['nutrition_basis']['calories'], 360);
  });

  test('meal correction carries operation, day and revision identity', () {
    const request = MealEditRequest(
      operationId: 'correction-1',
      dayId: '2026-09-05',
      expectedPlanRevision: 13,
      meal: Meal(
        name: 'Corrected lunch',
        emoji: '🥗',
        calories: 420,
        proteinG: 30,
        carbsG: 40,
        fatsG: 14,
        nutritionBasis: NutritionBasis(
          servingAmount: 1,
          servingUnit: 'bowl',
          calories: 420,
          proteinG: 30,
          carbsG: 40,
          fatsG: 14,
        ),
      ),
    );

    final json = request.toJson();

    expect(json['operation_id'], 'correction-1');
    expect(json['day_id'], '2026-09-05');
    expect(json['expected_plan_revision'], 13);
    expect((json['meal'] as Map)['name'], 'Corrected lunch');
  });
}
