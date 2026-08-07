import 'package:diet_coach_ai/shared/models/meal.dart';

/// One meal slot in a user-built custom day plan.
class CustomPlannedMeal {
  final String slot;
  final int order;
  final String name;
  final String emoji;
  final int prepMinutes;
  final String? cuisine;
  final String? servingSize;
  final bool isOptional;
  final List<MealComponent> components;

  const CustomPlannedMeal({
    required this.slot,
    required this.order,
    required this.name,
    required this.emoji,
    this.prepMinutes = 0,
    this.cuisine,
    this.servingSize,
    this.isOptional = false,
    required this.components,
  });

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'order': order,
    'name': name,
    'emoji': emoji,
    'prep_minutes': prepMinutes,
    'cuisine': cuisine,
    'serving_size': servingSize,
    'is_optional': isOptional,
    'components': components.map((component) => component.toJson()).toList(),
  };
}

/// Request payload for saving a fully custom day plan.
class CustomDayPlanRequest {
  final List<CustomPlannedMeal> meals;

  const CustomDayPlanRequest({required this.meals});

  Map<String, dynamic> toJson() => {
    'meals': meals.map((m) => m.toJson()).toList(),
  };
}
