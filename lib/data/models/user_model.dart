class UserModel {
  final String id;
  final String? email;
  final String? name;
  final double? age;
  final double? weight;
  final double? height;
  final String? gender;
  final String? activityLevel;
  final String? goal;
  final double? targetWeight;
  final List<String> dietaryRestrictions;
  final bool isOnboardingComplete;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.activityLevel,
    this.goal,
    this.targetWeight,
    this.dietaryRestrictions = const [],
    this.isOnboardingComplete = false,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    double? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? goal,
    double? targetWeight,
    List<String>? dietaryRestrictions,
    bool? isOnboardingComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }
}
