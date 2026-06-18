import 'meal.dart';

enum PlannedMealStatus {
  planned('planned'),
  logged('logged'),
  skipped('skipped');

  final String value;
  const PlannedMealStatus(this.value);

  static PlannedMealStatus fromString(String value) {
    return PlannedMealStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlannedMealStatus.planned,
    );
  }
}

/// One slot in the day's proactive meal plan.
class PlannedMeal {
  final String slot; // "breakfast", "lunch", "snack", "dinner", "late"
  final int order; // 0, 1, 2, 3, 4
  final Meal meal;
  final PlannedMealStatus status;
  final String? loggedMealId;
  final bool isOptional;

  const PlannedMeal({
    required this.slot,
    required this.order,
    required this.meal,
    required this.status,
    this.loggedMealId,
    this.isOptional = false,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
    slot: json['slot'] as String,
    order: json['order'] as int,
    meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
    status: PlannedMealStatus.fromString(json['status'] as String),
    loggedMealId: json['logged_meal_id'] as String?,
    isOptional: json['is_optional'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'order': order,
    'meal': meal.toJson(),
    'status': status.value,
    if (loggedMealId != null) 'logged_meal_id': loggedMealId,
    'is_optional': isOptional,
  };
}

/// When the user logs an off-plan meal, the backend generates a proposal
/// to adjust the remaining meals.
class ProposedPlan {
  final List<PlannedMeal> changedSlots;
  final String reason;

  const ProposedPlan({required this.changedSlots, required this.reason});

  factory ProposedPlan.fromJson(Map<String, dynamic> json) => ProposedPlan(
    changedSlots: (json['changed_slots'] as List)
        .map((e) => PlannedMeal.fromJson(e as Map<String, dynamic>))
        .toList(),
    reason: json['reason'] as String,
  );

  Map<String, dynamic> toJson() => {
    'changed_slots': changedSlots.map((e) => e.toJson()).toList(),
    'reason': reason,
  };
}
