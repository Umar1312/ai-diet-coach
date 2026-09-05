import 'meal_log_item.dart';
import 'home_models.dart';
import 'planned_meal.dart';

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
  final String id;
  final int revision;
  final String contextVersion;
  final AdaptationStatus adaptationStatus;
  final AdaptationAccess adaptationAccess;
  final String dayId;
  final String userId;
  final MacroTargets targets;
  final MacroTargets consumed;
  final List<MealLogItem> meals;
  final List<PlannedMeal> plannedMeals;
  final ProposedPlan? pendingProposal;
  final NextMealRecommendation? nextMeal;
  final RecalibrationStatus? recalibration;
  final DayStatus dayStatus;
  final String aiCardText;
  final AICardState aiCardState;
  final String generatedAt;

  const DailyPlan({
    this.id = '',
    this.revision = 0,
    this.contextVersion = '',
    this.adaptationStatus = AdaptationStatus.idle,
    this.adaptationAccess = const AdaptationAccess(),
    required this.dayId,
    required this.userId,
    required this.targets,
    required this.consumed,
    required this.meals,
    required this.plannedMeals,
    this.pendingProposal,
    this.nextMeal,
    this.recalibration,
    required this.dayStatus,
    required this.aiCardText,
    required this.aiCardState,
    required this.generatedAt,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
    id: json['id'] as String,
    revision: json['revision'] as int,
    contextVersion: json['context_version'] as String,
    adaptationStatus: AdaptationStatus.fromString(
      json['adaptation_status'] as String,
    ),
    adaptationAccess: AdaptationAccess.fromJson(
      json['adaptation_access'] as Map<String, dynamic>,
    ),
    dayId: json['day_id'] as String,
    userId: json['user_id'] as String,
    targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
    consumed: MacroTargets.fromJson(json['consumed'] as Map<String, dynamic>),
    meals: (json['meals'] as List)
        .map((e) => MealLogItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    plannedMeals:
        (json['planned_meals'] as List?)
            ?.map((e) => PlannedMeal.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    pendingProposal: json['pending_proposal'] == null
        ? null
        : ProposedPlan.fromJson(
            json['pending_proposal'] as Map<String, dynamic>,
          ),
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
    dayStatus: DayStatusParsing.fromString(
      json['day_status'] as String? ?? 'on_track',
    ),
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

class AdaptationAccess {
  final bool isPro;
  final int allowanceTotal;
  final int acceptedCount;
  final int remaining;
  final bool canAccept;

  const AdaptationAccess({
    this.isPro = false,
    this.allowanceTotal = 3,
    this.acceptedCount = 0,
    this.remaining = 3,
    this.canAccept = true,
  });

  factory AdaptationAccess.fromJson(Map<String, dynamic> json) =>
      AdaptationAccess(
        isPro: json['is_pro'] as bool,
        allowanceTotal: json['allowance_total'] as int,
        acceptedCount: json['accepted_count'] as int,
        remaining: json['remaining'] as int,
        canAccept: json['can_accept'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'is_pro': isPro,
    'allowance_total': allowanceTotal,
    'accepted_count': acceptedCount,
    'remaining': remaining,
    'can_accept': canAccept,
  };
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
