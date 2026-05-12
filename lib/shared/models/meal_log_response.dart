import 'meal_log_item.dart';
import 'dashboard_state.dart';

class MealLogResponse {
  final MealLogItem log;
  final DailyPlan updatedPlan;

  const MealLogResponse({required this.log, required this.updatedPlan});

  factory MealLogResponse.fromJson(Map<String, dynamic> json) =>
      MealLogResponse(
        log: MealLogItem.fromJson(json['log'] as Map<String, dynamic>),
        updatedPlan: DailyPlan.fromJson(
          json['updated_plan'] as Map<String, dynamic>,
        ),
      );
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
  final String foodName;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;

  const MealEditRequest({
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  Map<String, dynamic> toJson() => {
    'food_name': foodName,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
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
