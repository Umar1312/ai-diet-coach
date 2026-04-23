class MacroModel {
  final double calories;
  final double carbs;
  final double protein;
  final double fats;

  MacroModel({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
  });

  MacroModel copyWith({
    double? calories,
    double? carbs,
    double? protein,
    double? fats,
  }) {
    return MacroModel(
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fats: fats ?? this.fats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
    };
  }

  factory MacroModel.fromJson(Map<String, dynamic> json) {
    return MacroModel(
      calories: json['calories']?.toDouble() ?? 0,
      carbs: json['carbs']?.toDouble() ?? 0,
      protein: json['protein']?.toDouble() ?? 0,
      fats: json['fats']?.toDouble() ?? 0,
    );
  }

  // Calculate macros based on user stats using Mifflin-St Jeor Equation
  static MacroModel calculateFromUser({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    // Base metabolic rate (Mifflin-St Jeor)
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Activity multiplier
    double activityMultiplier;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'lightly active':
        activityMultiplier = 1.375;
        break;
      case 'moderately active':
        activityMultiplier = 1.55;
        break;
      case 'very active':
        activityMultiplier = 1.725;
        break;
      case 'extremely active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.375;
    }

    double tdee = bmr * activityMultiplier;

    // Adjust for goal
    switch (goal.toLowerCase()) {
      case 'lose weight':
        tdee -= 500;
        break;
      case 'gain muscle':
        tdee += 300;
        break;
      case 'maintain':
      default:
        break;
    }

    // Calculate macros (40% carbs, 30% protein, 30% fats)
    double calories = tdee.roundToDouble();
    double carbs = ((calories * 0.4) / 4).roundToDouble();
    double protein = ((calories * 0.3) / 4).roundToDouble();
    double fats = ((calories * 0.3) / 9).roundToDouble();

    return MacroModel(
      calories: calories,
      carbs: carbs,
      protein: protein,
      fats: fats,
    );
  }
}
