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
