class RecommendedDish {
  final String dishName;
  final String whyItFits;
  final String modifications;
  final int estimatedCalories;
  final int estimatedProtein;
  final int estimatedCarbs;
  final int estimatedFats;

  const RecommendedDish({
    required this.dishName,
    required this.whyItFits,
    required this.modifications,
    required this.estimatedCalories,
    required this.estimatedProtein,
    required this.estimatedCarbs,
    required this.estimatedFats,
  });

  factory RecommendedDish.fromJson(Map<String, dynamic> json) =>
      RecommendedDish(
        dishName: json['dish_name'] as String,
        whyItFits: json['why_it_fits'] as String,
        modifications: json['modifications'] as String,
        estimatedCalories: json['estimated_calories'] as int,
        estimatedProtein: json['estimated_protein'] as int,
        estimatedCarbs: json['estimated_carbs'] as int,
        estimatedFats: json['estimated_fats'] as int,
      );
}

class MenuScanResponse {
  final List<RecommendedDish> recommendations;
  final String restaurantContext;

  const MenuScanResponse({
    required this.recommendations,
    required this.restaurantContext,
  });

  factory MenuScanResponse.fromJson(Map<String, dynamic> json) =>
      MenuScanResponse(
        recommendations: (json['recommendations'] as List)
            .map((e) => RecommendedDish.fromJson(e as Map<String, dynamic>))
            .toList(),
        restaurantContext: json['restaurant_context'] as String,
      );
}
