import 'meal_log_item.dart';
import 'home_models.dart';

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

class DailyPlan {
  final String dayId;
  final String userId;
  final MacroTargets targets;
  final MacroTargets consumed;
  final List<MealLogItem> meals;
  final List<FlexPlanSlot> flexPlan;
  final NextMealRecommendation? nextMeal;
  final RecalibrationStatus? recalibration;
  final DayStatus dayStatus;
  final String aiCardText;
  final AICardState aiCardState;
  final String generatedAt;

  const DailyPlan({
    required this.dayId,
    required this.userId,
    required this.targets,
    required this.consumed,
    required this.meals,
    required this.flexPlan,
    this.nextMeal,
    this.recalibration,
    required this.dayStatus,
    required this.aiCardText,
    required this.aiCardState,
    required this.generatedAt,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
    dayId: json['day_id'] as String,
    userId: json['user_id'] as String,
    targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
    consumed: MacroTargets.fromJson(json['consumed'] as Map<String, dynamic>),
    meals: (json['meals'] as List)
        .map((e) => MealLogItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    flexPlan: (json['flex_plan'] as List)
        .map((e) => FlexPlanSlot.fromJson(e as Map<String, dynamic>))
        .toList(),
    nextMeal: json['next_meal'] == null
        ? null
        : NextMealRecommendation.fromJson(
            json['next_meal'] as Map<String, dynamic>,
          ),
    recalibration: json['recalibration'] == null
        ? null
        : RecalibrationStatus.fromJson(
            json['recalibration'] as Map<String, dynamic>,
          ),
    dayStatus: DayStatusParsing.fromString(json['day_status'] as String),
    aiCardText: json['ai_card_text'] as String,
    aiCardState: AICardState.fromString(json['ai_card_state'] as String),
    generatedAt: json['generated_at'] as String,
  );

  int get caloriesLeft => targets.calories - consumed.calories;
  double get calorieProgress =>
      (consumed.calories / targets.calories).clamp(0.0, 1.0);
  double get proteinProgress =>
      (consumed.proteinG / targets.proteinG).clamp(0.0, 1.0);
  double get carbsProgress =>
      (consumed.carbsG / targets.carbsG).clamp(0.0, 1.0);
  double get fatsProgress => (consumed.fatsG / targets.fatsG).clamp(0.0, 1.0);
}

class MacroTargets {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;

  const MacroTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  factory MacroTargets.fromJson(Map<String, dynamic> json) => MacroTargets(
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    carbsG: json['carbs_g'] as int,
    fatsG: json['fats_g'] as int,
  );

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
  };
}

/// Backward compatibility alias for code still referencing DashboardState.
typedef DashboardState = DailyPlan;
