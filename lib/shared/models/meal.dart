class Meal {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final String? imageUrl;
  final String loggedAt;
  final String source;

  const Meal({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.imageUrl,
    required this.loggedAt,
    required this.source,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    foodName: json['food_name'] as String,
    calories: json['calories'] as int,
    protein: json['protein'] as int,
    carbs: json['carbs'] as int,
    fats: json['fats'] as int,
    imageUrl: json['image_url'] as String?,
    loggedAt: json['logged_at'] as String,
    source: json['source'] as String,
  );

  Map<String, dynamic> toJson() => {
    'food_name': foodName,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'image_url': imageUrl,
    'logged_at': loggedAt,
    'source': source,
  };
}
