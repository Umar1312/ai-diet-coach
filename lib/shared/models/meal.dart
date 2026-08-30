class MealComponent {
  final String? foodItemId;
  final String name;
  final String emoji;
  final int quantity;
  final String? servingSize;
  final int caloriesPerServing;
  final int proteinGPerServing;
  final int carbsGPerServing;
  final int fatsGPerServing;

  const MealComponent({
    this.foodItemId,
    required this.name,
    required this.emoji,
    this.quantity = 1,
    this.servingSize,
    required this.caloriesPerServing,
    required this.proteinGPerServing,
    required this.carbsGPerServing,
    required this.fatsGPerServing,
  });

  int get totalCalories => caloriesPerServing * quantity;
  int get totalProteinG => proteinGPerServing * quantity;
  int get totalCarbsG => carbsGPerServing * quantity;
  int get totalFatsG => fatsGPerServing * quantity;

  MealComponent copyWith({int? quantity}) {
    return MealComponent(
      foodItemId: foodItemId,
      name: name,
      emoji: emoji,
      quantity: quantity ?? this.quantity,
      servingSize: servingSize,
      caloriesPerServing: caloriesPerServing,
      proteinGPerServing: proteinGPerServing,
      carbsGPerServing: carbsGPerServing,
      fatsGPerServing: fatsGPerServing,
    );
  }

  factory MealComponent.fromJson(Map<String, dynamic> json) => MealComponent(
    foodItemId: json['food_item_id'] as String?,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    quantity: json['quantity'] as int? ?? 1,
    servingSize: json['serving_size'] as String?,
    caloriesPerServing: json['calories_per_serving'] as int,
    proteinGPerServing: json['protein_g_per_serving'] as int,
    carbsGPerServing: json['carbs_g_per_serving'] as int,
    fatsGPerServing: json['fats_g_per_serving'] as int,
  );

  Map<String, dynamic> toJson() => {
    'food_item_id': foodItemId,
    'name': name,
    'emoji': emoji,
    'quantity': quantity,
    'serving_size': servingSize,
    'calories_per_serving': caloriesPerServing,
    'protein_g_per_serving': proteinGPerServing,
    'carbs_g_per_serving': carbsGPerServing,
    'fats_g_per_serving': fatsGPerServing,
  };
}

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
  final List<MealComponent> components;

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
    this.components = const [],
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
    components: (json['components'] as List? ?? const [])
        .map((e) => MealComponent.fromJson(e as Map<String, dynamic>))
        .toList(),
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
    'components': components.map((component) => component.toJson()).toList(),
  };
}
