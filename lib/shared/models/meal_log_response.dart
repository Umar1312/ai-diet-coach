import 'meal.dart';
import 'dashboard_state.dart';

class MealLogResponse {
  final Meal meal;
  final DailyPlan updatedPlan;

  const MealLogResponse({required this.meal, required this.updatedPlan});

  factory MealLogResponse.fromJson(Map<String, dynamic> json) =>
      MealLogResponse(
        meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
        updatedPlan: DailyPlan.fromJson(
          json['updated_plan'] as Map<String, dynamic>,
        ),
      );
}

class ManualLogRequest {
  final String foodName;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String source;

  const ManualLogRequest({
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'food_name': foodName,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
    'source': source,
  };
}
