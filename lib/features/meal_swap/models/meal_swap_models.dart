import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

enum MealSwapReason {
  surpriseMe('surprise_me', 'Best fit'),
  noIngredients('no_ingredients', "Don't have ingredients"),
  quicker('quicker', 'Something quicker'),
  notInMood('not_in_mood', 'Different vibe'),
  eatingOut('eating_out', 'Eating out'),
  lighter('lighter', 'Make it lighter'),
  moreProtein('more_protein', 'More protein');

  final String value;
  final String label;

  const MealSwapReason(this.value, this.label);
}

class MealAlternative {
  final Meal meal;
  final String whyItFits;
  final List<String> usedPantryItems;
  final int calorieDelta;
  final int proteinDelta;
  final int carbsDelta;
  final int fatsDelta;

  const MealAlternative({
    required this.meal,
    required this.whyItFits,
    required this.usedPantryItems,
    required this.calorieDelta,
    required this.proteinDelta,
    required this.carbsDelta,
    required this.fatsDelta,
  });

  factory MealAlternative.fromJson(Map<String, dynamic> json) =>
      MealAlternative(
        meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
        whyItFits: json['why_it_fits'] as String,
        usedPantryItems: (json['used_pantry_items'] as List? ?? const [])
            .cast<String>(),
        calorieDelta: json['calorie_delta'] as int,
        proteinDelta: json['protein_delta'] as int,
        carbsDelta: json['carbs_delta'] as int,
        fatsDelta: json['fats_delta'] as int,
      );
}

class SlotAlternativesResponse {
  final int slotOrder;
  final Meal currentMeal;
  final List<MealAlternative> alternatives;

  const SlotAlternativesResponse({
    required this.slotOrder,
    required this.currentMeal,
    required this.alternatives,
  });

  factory SlotAlternativesResponse.fromJson(
    Map<String, dynamic> json,
  ) => SlotAlternativesResponse(
    slotOrder: json['slot_order'] as int,
    currentMeal: Meal.fromJson(json['current_meal'] as Map<String, dynamic>),
    alternatives: (json['alternatives'] as List)
        .map((item) => MealAlternative.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class SlotReplacementImpact {
  final int calorieDelta;
  final int proteinDelta;
  final int carbsDelta;
  final int fatsDelta;
  final List<PlannedMeal> changedSlots;
  final String message;

  const SlotReplacementImpact({
    required this.calorieDelta,
    required this.proteinDelta,
    required this.carbsDelta,
    required this.fatsDelta,
    required this.changedSlots,
    required this.message,
  });

  factory SlotReplacementImpact.fromJson(Map<String, dynamic> json) =>
      SlotReplacementImpact(
        calorieDelta: json['calorie_delta'] as int,
        proteinDelta: json['protein_delta'] as int,
        carbsDelta: json['carbs_delta'] as int,
        fatsDelta: json['fats_delta'] as int,
        changedSlots: (json['changed_slots'] as List? ?? const [])
            .map((item) => PlannedMeal.fromJson(item as Map<String, dynamic>))
            .toList(),
        message: json['message'] as String,
      );
}

class SlotReplacementResponse {
  final DailyPlan updatedPlan;
  final SlotReplacementImpact impact;
  final bool requiresConfirmation;

  const SlotReplacementResponse({
    required this.updatedPlan,
    required this.impact,
    required this.requiresConfirmation,
  });

  factory SlotReplacementResponse.fromJson(Map<String, dynamic> json) =>
      SlotReplacementResponse(
        updatedPlan: DailyPlan.fromJson(
          json['updated_plan'] as Map<String, dynamic>,
        ),
        impact: SlotReplacementImpact.fromJson(
          json['impact'] as Map<String, dynamic>,
        ),
        requiresConfirmation: json['requires_confirmation'] as bool? ?? false,
      );
}
