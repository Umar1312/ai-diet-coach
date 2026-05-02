import 'home_models.dart';

class SwapResponse {
  final NextMealRecommendation nextMeal;

  const SwapResponse({required this.nextMeal});

  factory SwapResponse.fromJson(Map<String, dynamic> json) => SwapResponse(
    nextMeal: NextMealRecommendation.fromJson(
      json['next_meal'] as Map<String, dynamic>,
    ),
  );
}

class QuickActionResponse {
  final NextMealRecommendation nextMeal;

  const QuickActionResponse({required this.nextMeal});

  factory QuickActionResponse.fromJson(Map<String, dynamic> json) =>
      QuickActionResponse(
        nextMeal: NextMealRecommendation.fromJson(
          json['next_meal'] as Map<String, dynamic>,
        ),
      );
}

class CravingRequest {
  final String cravingText;
  final List<String> tags;
  final bool? preferPantry;

  const CravingRequest({
    required this.cravingText,
    required this.tags,
    this.preferPantry,
  });

  Map<String, dynamic> toJson() => {
    'craving_text': cravingText,
    'tags': tags,
    if (preferPantry != null) 'prefer_pantry': preferPantry,
  };
}

class CravingResponse {
  final NextMealRecommendation nextMeal;

  const CravingResponse({required this.nextMeal});

  factory CravingResponse.fromJson(Map<String, dynamic> json) =>
      CravingResponse(
        nextMeal: NextMealRecommendation.fromJson(
          json['next_meal'] as Map<String, dynamic>,
        ),
      );
}
