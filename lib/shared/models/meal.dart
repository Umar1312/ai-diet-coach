class Meal {
  final String id;
  final String userId;
  final String foodName;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String? imageUrl;
  final String loggedAt;
  final String source;
  final String dayId;

  const Meal({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.imageUrl,
    required this.loggedAt,
    required this.source,
    required this.dayId,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    foodName: json['food_name'] as String,
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    carbsG: json['carbs_g'] as int,
    fatsG: json['fats_g'] as int,
    imageUrl: json['image_url'] as String?,
    loggedAt: json['logged_at'] as String,
    source: json['source'] as String,
    dayId: json['day_id'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'food_name': foodName,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
    'image_url': imageUrl,
    'logged_at': loggedAt,
    'source': source,
    'day_id': dayId,
  };
}
