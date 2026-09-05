class MealComponent {
  final String? foodItemId;
  final String name;
  final String emoji;
  final double quantity;
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

  int get totalCalories => (caloriesPerServing * quantity).round();
  int get totalProteinG => (proteinGPerServing * quantity).round();
  int get totalCarbsG => (carbsGPerServing * quantity).round();
  int get totalFatsG => (fatsGPerServing * quantity).round();

  MealComponent copyWith({double? quantity}) {
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
    quantity: (json['quantity'] as num? ?? 1).toDouble(),
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

class NutritionBasis {
  final double servingAmount;
  final String servingUnit;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;

  const NutritionBasis({
    required this.servingAmount,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  factory NutritionBasis.fromJson(Map<String, dynamic> json) => NutritionBasis(
    servingAmount: (json['serving_amount'] as num).toDouble(),
    servingUnit: json['serving_unit'] as String,
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    carbsG: json['carbs_g'] as int,
    fatsG: json['fats_g'] as int,
  );

  Map<String, dynamic> toJson() => {
    'serving_amount': servingAmount,
    'serving_unit': servingUnit,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
  };
}

class MealIngredient {
  final String name;
  final double amount;
  final String unit;
  final bool? isAvailable;

  const MealIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.isAvailable,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) => MealIngredient(
    name: json['name'] as String,
    amount: (json['amount'] as num).toDouble(),
    unit: json['unit'] as String,
    isAvailable: json['is_available'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
    if (isAvailable != null) 'is_available': isAvailable,
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
  final double servings;
  final String servingUnit;
  final NutritionBasis? nutritionBasis;
  final List<MealComponent> components;
  final List<MealIngredient> ingredients;
  final List<String> preparationSteps;

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
    this.servings = 1,
    this.servingUnit = 'serving',
    this.nutritionBasis,
    this.components = const [],
    this.ingredients = const [],
    this.preparationSteps = const [],
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
    servings: (json['servings'] as num? ?? 1).toDouble(),
    servingUnit: json['serving_unit'] as String? ?? 'serving',
    nutritionBasis: json['nutrition_basis'] == null
        ? null
        : NutritionBasis.fromJson(
            json['nutrition_basis'] as Map<String, dynamic>,
          ),
    components: (json['components'] as List? ?? const [])
        .map((e) => MealComponent.fromJson(e as Map<String, dynamic>))
        .toList(),
    ingredients: (json['ingredients'] as List? ?? const [])
        .map((e) => MealIngredient.fromJson(e as Map<String, dynamic>))
        .toList(),
    preparationSteps: (json['preparation_steps'] as List? ?? const [])
        .map((e) => e as String)
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
    'servings': servings,
    'serving_unit': servingUnit,
    if (nutritionBasis != null) 'nutrition_basis': nutritionBasis!.toJson(),
    'components': components.map((component) => component.toJson()).toList(),
    'ingredients': ingredients
        .map((ingredient) => ingredient.toJson())
        .toList(),
    'preparation_steps': preparationSteps,
  };
}
