import 'meal_log_item.dart';
import 'dashboard_state.dart';
import 'meal.dart';
import 'planned_meal.dart';

enum MealLogIntent {
  planned('planned'),
  replacement('replacement'),
  extra('extra');

  final String value;
  const MealLogIntent(this.value);
}

class AdaptationResult {
  final AdaptationStatus status;
  final ProposedPlan? proposal;
  final bool retryable;
  final String? reasonCode;

  const AdaptationResult({
    required this.status,
    this.proposal,
    this.retryable = false,
    this.reasonCode,
  });

  factory AdaptationResult.fromJson(Map<String, dynamic> json) =>
      AdaptationResult(
        status: AdaptationStatus.fromString(json['status'] as String),
        proposal: json['proposal'] == null
            ? null
            : ProposedPlan.fromJson(json['proposal'] as Map<String, dynamic>),
        retryable: json['retryable'] as bool? ?? false,
        reasonCode: json['reason_code'] as String?,
      );
}

class MealLogResponse {
  final MealLogItem log;
  final DailyPlan updatedPlan;
  final AdaptationResult adaptation;

  const MealLogResponse({
    required this.log,
    required this.updatedPlan,
    this.adaptation = const AdaptationResult(status: AdaptationStatus.idle),
  });

  factory MealLogResponse.fromJson(Map<String, dynamic> json) =>
      MealLogResponse(
        log: MealLogItem.fromJson(json['log'] as Map<String, dynamic>),
        updatedPlan: DailyPlan.fromJson(
          json['updated_plan'] as Map<String, dynamic>,
        ),
        adaptation: AdaptationResult.fromJson(
          json['adaptation'] as Map<String, dynamic>,
        ),
      );
}

class MealLogMutationRequest {
  final String operationId;
  final String dayId;
  final int expectedPlanRevision;
  final MealLogIntent intent;
  final String? slotId;
  final String source;
  final Meal meal;

  const MealLogMutationRequest({
    required this.operationId,
    required this.dayId,
    required this.expectedPlanRevision,
    required this.intent,
    this.slotId,
    required this.source,
    required this.meal,
  });

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'day_id': dayId,
    'expected_plan_revision': expectedPlanRevision,
    'intent': intent.value,
    if (slotId != null) 'slot_id': slotId,
    'source': source,
    'meal': meal.toJson(),
  };
}

class TextLogRequest {
  final String description;
  final String? context;
  final List<String>? pantryItemIds;
  final String? slot;

  const TextLogRequest({
    required this.description,
    this.context,
    this.pantryItemIds,
    this.slot,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    if (context != null) 'context': context,
    if (pantryItemIds != null && pantryItemIds!.isNotEmpty)
      'pantry_item_ids': pantryItemIds,
    if (slot != null) 'slot': slot,
  };
}

class ManualLogRequest {
  final String foodName;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String source;
  final String? slot;

  const ManualLogRequest({
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.source,
    this.slot,
  });

  Map<String, dynamic> toJson() => {
    'food_name': foodName,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
    'source': source,
    if (slot != null) 'slot': slot,
  };
}

class MealEditRequest {
  final String operationId;
  final String dayId;
  final int expectedPlanRevision;
  final Meal meal;

  const MealEditRequest({
    required this.operationId,
    required this.dayId,
    required this.expectedPlanRevision,
    required this.meal,
  });

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'day_id': dayId,
    'expected_plan_revision': expectedPlanRevision,
    'meal': meal.toJson(),
  };
}

class LogRecommendationRequest {
  final String foodName;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String? slot;

  const LogRecommendationRequest({
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.slot,
  });

  Map<String, dynamic> toJson() => {
    'food_name': foodName,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
    if (slot != null) 'slot': slot,
  };
}
