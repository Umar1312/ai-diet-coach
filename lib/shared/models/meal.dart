class Meal {
  final String name;
  final String emoji;
  final int prepMinutes;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String? cuisine;
  final String? servingSize;

  const Meal({
    required this.name,
    required this.emoji,
    this.prepMinutes = 0,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.cuisine,
    this.servingSize,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    prepMinutes: json['prep_minutes'] as int? ?? 0,
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    carbsG: json['carbs_g'] as int,
    fatsG: json['fats_g'] as int,
    cuisine: json['cuisine'] as String?,
    servingSize: json['serving_size'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    'prep_minutes': prepMinutes,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
    'cuisine': cuisine,
    'serving_size': servingSize,
  };
}
