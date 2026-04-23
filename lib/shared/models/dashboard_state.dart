import 'meal.dart';

enum AICardState {
  onTrack('on_track'),
  skippedMeal('skipped_meal'),
  behindProtein('behind_protein'),
  calorieLimit('calorie_limit'),
  goalHit('goal_hit');

  final String value;
  const AICardState(this.value);

  static AICardState fromString(String value) {
    return AICardState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AICardState.onTrack,
    );
  }
}

class DashboardState {
  final int consumedCalories;
  final int consumedProtein;
  final int consumedCarbs;
  final int consumedFats;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFats;
  final List<Meal> meals;
  final String aiCardText;
  final AICardState aiCardState;

  const DashboardState({
    required this.consumedCalories,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFats,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
    required this.meals,
    required this.aiCardText,
    required this.aiCardState,
  });

  factory DashboardState.fromJson(Map<String, dynamic> json) => DashboardState(
    consumedCalories: json['consumed_calories'] as int,
    consumedProtein: json['consumed_protein'] as int,
    consumedCarbs: json['consumed_carbs'] as int,
    consumedFats: json['consumed_fats'] as int,
    targetCalories: json['target_calories'] as int,
    targetProtein: json['target_protein'] as int,
    targetCarbs: json['target_carbs'] as int,
    targetFats: json['target_fats'] as int,
    meals: (json['meals'] as List)
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList(),
    aiCardText: json['ai_card_text'] as String,
    aiCardState: AICardState.fromString(json['ai_card_state'] as String),
  );

  int get caloriesLeft => targetCalories - consumedCalories;
  double get calorieProgress =>
      (consumedCalories / targetCalories).clamp(0.0, 1.0);
  double get proteinProgress =>
      (consumedProtein / targetProtein).clamp(0.0, 1.0);
  double get carbsProgress => (consumedCarbs / targetCarbs).clamp(0.0, 1.0);
  double get fatsProgress => (consumedFats / targetFats).clamp(0.0, 1.0);
}
