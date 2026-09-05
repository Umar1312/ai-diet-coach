import 'meal.dart';

class MealLogItem {
  final String operationId;
  final String intent;
  final String? slotId;
  final String id;
  final String userId;
  final String dayId;
  final String source;
  final DateTime loggedAt;
  final String? imageUrl;
  final Meal meal;

  const MealLogItem({
    this.operationId = '',
    this.intent = 'extra',
    this.slotId,
    required this.id,
    required this.userId,
    required this.dayId,
    required this.source,
    required this.loggedAt,
    this.imageUrl,
    required this.meal,
  });

  factory MealLogItem.fromJson(Map<String, dynamic> json) => MealLogItem(
    operationId: json['operation_id'] as String,
    intent: json['intent'] as String,
    slotId: json['slot_id'] as String?,
    id: json['id'] as String,
    userId: json['user_id'] as String,
    dayId: json['day_id'] as String,
    source: json['source'] as String,
    loggedAt: DateTime.parse(json['logged_at'] as String),
    imageUrl: json['image_url'] as String?,
    meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'operation_id': operationId,
    'intent': intent,
    if (slotId != null) 'slot_id': slotId,
    'id': id,
    'user_id': userId,
    'day_id': dayId,
    'source': source,
    'logged_at': loggedAt.toIso8601String(),
    'image_url': imageUrl,
    'meal': meal.toJson(),
  };
}
