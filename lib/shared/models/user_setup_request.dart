class UserSetupRequest {
  final String name;
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final int activityLevel;
  final String goal;
  final double targetWeightKg;
  final List<String> dietaryRestrictions;

  const UserSetupRequest({
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.targetWeightKg,
    required this.dietaryRestrictions,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender,
    'age': age,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity_level': activityLevel,
    'goal': goal,
    'target_weight_kg': targetWeightKg,
    'dietary_restrictions': dietaryRestrictions,
  };
}

class UserSetupResponse {
  final String uid;
  final String name;
  final int tdeeCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFats;
  final List<String> dietaryRestrictions;
  final bool isPro;

  const UserSetupResponse({
    required this.uid,
    required this.name,
    required this.tdeeCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
    required this.dietaryRestrictions,
    required this.isPro,
  });

  factory UserSetupResponse.fromJson(Map<String, dynamic> json) =>
      UserSetupResponse(
        uid: json['uid'] as String,
        name: json['name'] as String,
        tdeeCalories: json['tdee_calories'] as int,
        targetProtein: json['target_protein'] as int,
        targetCarbs: json['target_carbs'] as int,
        targetFats: json['target_fats'] as int,
        dietaryRestrictions: (json['dietary_restrictions'] as List)
            .cast<String>(),
        isPro: json['is_pro'] as bool,
      );
}
