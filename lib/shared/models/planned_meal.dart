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

enum AdaptationStatus {
  idle('idle'),
  checking('checking'),
  proposalReady('proposal_ready'),
  notNeeded('not_needed'),
  unavailable('unavailable'),
  exhausted('exhausted');

  final String value;
  const AdaptationStatus(this.value);

  static AdaptationStatus fromString(String value) =>
      AdaptationStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => AdaptationStatus.idle,
      );
}

/// One slot in the day's proactive meal plan.
class PlannedMeal {
  final String id;
  final String slot; // "breakfast", "lunch", "snack", "dinner", "late"
  final int order; // 0, 1, 2, 3, 4
  final Meal meal;
  final PlannedMealStatus status;
  final String? loggedMealId;
  final bool isOptional;
  final bool isProtected;

  const PlannedMeal({
    this.id = '',
    required this.slot,
    required this.order,
    required this.meal,
    required this.status,
    this.loggedMealId,
    this.isOptional = false,
    this.isProtected = false,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
    id: json['id'] as String,
    slot: json['slot'] as String,
    order: json['order'] as int,
    meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
    status: PlannedMealStatus.fromString(json['status'] as String),
    loggedMealId: json['logged_meal_id'] as String?,
    isOptional: json['is_optional'] as bool? ?? false,
    isProtected: json['is_protected'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slot': slot,
    'order': order,
    'meal': meal.toJson(),
    'status': status.value,
    if (loggedMealId != null) 'logged_meal_id': loggedMealId,
    'is_optional': isOptional,
    'is_protected': isProtected,
  };
}

class PlanPatch {
  final String slotId;
  final Meal meal;

  const PlanPatch({required this.slotId, required this.meal});

  factory PlanPatch.fromJson(Map<String, dynamic> json) => PlanPatch(
    slotId: json['slot_id'] as String,
    meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'slot_id': slotId, 'meal': meal.toJson()};
}

/// When the user logs an off-plan meal, the backend generates a proposal
/// to adjust the remaining meals.
class ProposedPlan {
  final String id;
  final int sourcePlanRevision;
  final String contextVersion;
  final String trigger;
  final List<PlanPatch> patches;
  final List<PlannedMeal> changedSlots;
  final String reason;

  const ProposedPlan({
    this.id = '',
    this.sourcePlanRevision = 0,
    this.contextVersion = '',
    this.trigger = 'meal_logged',
    this.patches = const [],
    this.changedSlots = const [],
    required this.reason,
  });

  factory ProposedPlan.fromJson(Map<String, dynamic> json) => ProposedPlan(
    id: json['id'] as String,
    sourcePlanRevision: json['source_plan_revision'] as int,
    contextVersion: json['context_version'] as String,
    trigger: json['trigger'] as String,
    patches: (json['patches'] as List)
        .map((e) => PlanPatch.fromJson(e as Map<String, dynamic>))
        .toList(),
    changedSlots: (json['changed_slots'] as List? ?? const [])
        .map((e) => PlannedMeal.fromJson(e as Map<String, dynamic>))
        .toList(),
    reason: json['reason'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'source_plan_revision': sourcePlanRevision,
    'context_version': contextVersion,
    'trigger': trigger,
    'patches': patches.map((e) => e.toJson()).toList(),
    'changed_slots': changedSlots.map((e) => e.toJson()).toList(),
    'reason': reason,
  };

  List<PlannedMeal> previewChanges(Iterable<PlannedMeal> committed) {
    if (patches.isEmpty) return changedSlots;
    final byId = {for (final slot in committed) slot.id: slot};
    return patches.where((patch) => byId.containsKey(patch.slotId)).map((
      patch,
    ) {
      final slot = byId[patch.slotId]!;
      return PlannedMeal(
        id: slot.id,
        slot: slot.slot,
        order: slot.order,
        meal: patch.meal,
        status: slot.status,
        loggedMealId: slot.loggedMealId,
        isOptional: slot.isOptional,
        isProtected: slot.isProtected,
      );
    }).toList();
  }
}
