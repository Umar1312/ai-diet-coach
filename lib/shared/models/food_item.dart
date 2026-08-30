import 'package:diet_coach_ai/shared/models/meal.dart';

class FoodItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String servingSize;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final List<String> aliases;
  final String? country;
  final List<String> cuisines;
  final List<String> dietaryTags;
  final int prepMinutes;
  final String? source;

  const FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.servingSize,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.aliases = const [],
    this.country,
    this.cuisines = const [],
    this.dietaryTags = const [],
    this.prepMinutes = 0,
    this.source,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    category: json['category'] as String,
    servingSize: json['serving_size'] as String,
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    carbsG: json['carbs_g'] as int,
    fatsG: json['fats_g'] as int,
    aliases: (json['aliases'] as List? ?? const []).cast<String>(),
    country: json['country'] as String?,
    cuisines: (json['cuisines'] as List? ?? const []).cast<String>(),
    dietaryTags: (json['dietary_tags'] as List? ?? const []).cast<String>(),
    prepMinutes: json['prep_minutes'] as int? ?? 0,
    source: json['source'] as String?,
  );

  MealComponent toComponent({int quantity = 1}) => MealComponent(
    foodItemId: id,
    name: name,
    emoji: emoji,
    quantity: quantity,
    servingSize: servingSize,
    caloriesPerServing: calories,
    proteinGPerServing: proteinG,
    carbsGPerServing: carbsG,
    fatsGPerServing: fatsG,
  );
}

class FoodSearchResponse {
  final List<FoodItem> items;
  final int total;
  final int page;
  final int pageSize;

  const FoodSearchResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory FoodSearchResponse.fromJson(Map<String, dynamic> json) =>
      FoodSearchResponse(
        items: (json['items'] as List)
            .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
      );
}
