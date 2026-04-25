import 'dashboard_state.dart';

export 'dashboard_state.dart' show MacroTargets;

class UserSetupRequest {
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;
  final double targetWeightKg;
  final List<String> dietaryRestrictions;

  const UserSetupRequest({
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
  final User user;
  final DailyPlan plan;

  const UserSetupResponse({required this.user, required this.plan});

  factory UserSetupResponse.fromJson(Map<String, dynamic> json) =>
      UserSetupResponse(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        plan: DailyPlan.fromJson(json['plan'] as Map<String, dynamic>),
      );
}

class User {
  final String id;
  final String? email;
  final String createdAt;
  final String updatedAt;
  final UserProfile profile;
  final MacroTargets targets;

  const User({
    required this.id,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.profile,
    required this.targets,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String?,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
    targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
  );
}

class UserProfile {
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final String activityLevel;
  final String goal;
  final List<String> dietaryRestrictions;

  const UserProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.goal,
    required this.dietaryRestrictions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    gender: json['gender'] as String,
    age: json['age'] as int,
    heightCm: (json['height_cm'] as num).toDouble(),
    weightKg: (json['weight_kg'] as num).toDouble(),
    targetWeightKg: (json['target_weight_kg'] as num).toDouble(),
    activityLevel: json['activity_level'] as String,
    goal: json['goal'] as String,
    dietaryRestrictions: (json['dietary_restrictions'] as List)
        .map((e) => e as String)
        .toList(),
  );
}
