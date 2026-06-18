/// One meal slot in a user-built custom day plan.
class CustomPlannedMeal {
  final String slot;
  final int order;
  final String name;
  final String emoji;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;

  const CustomPlannedMeal({
    required this.slot,
    required this.order,
    required this.name,
    required this.emoji,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'order': order,
    'name': name,
    'emoji': emoji,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
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
