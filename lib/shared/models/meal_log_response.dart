import 'meal.dart';
import 'dashboard_state.dart';

class MealLogResponse {
  final Meal meal;
  final DashboardState updatedState;

  const MealLogResponse({required this.meal, required this.updatedState});

  factory MealLogResponse.fromJson(Map<String, dynamic> json) =>
      MealLogResponse(
        meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
        updatedState: DashboardState.fromJson(
          json['updated_state'] as Map<String, dynamic>,
        ),
      );
}
