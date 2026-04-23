class AppConstants {
  static const String appName = 'AI Diet Buddy';
  static const String appTagline = 'Your Personal AI Nutrition Coach';

  // API
  static const String apiBaseUrl = 'https://api.aidietary.app/api/v1';

  // Onboarding
  static const int onboardingSteps = 9;

  // Macro Defaults
  static const double defaultCalories = 2000;
  static const double defaultCarbs = 175;
  static const double defaultProtein = 200;
  static const double defaultFats = 56;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI Constants
  static const double defaultPadding = 24.0;
  static const double smallPadding = 16.0;
  static const double largePadding = 32.0;
  static const double defaultRadius = 16.0;
  static const double smallRadius = 12.0;
  static const double largeRadius = 24.0;

  // Macro Ring Sizes
  static const double macroRingSize = 120.0;
  static const double macroRingStrokeWidth = 8.0;
  static const double macroRingSizeSmall = 80.0;
  static const double macroRingStrokeWidthSmall = 6.0;

  // Max image upload size (bytes)
  static const int maxImageUploadBytes = 800 * 1024;

  // Paywall
  static const String monthlyPrice = '\$6.99';
  static const String yearlyPrice = '\$39.99';
  static const String lifetimePrice = '\$59.99';

  // Dietary Restrictions
  static const List<Map<String, String>> dietaryRestrictions = [
    {'value': 'vegan', 'label': 'Vegan'},
    {'value': 'vegetarian', 'label': 'Vegetarian'},
    {'value': 'keto', 'label': 'Keto'},
    {'value': 'gluten_free', 'label': 'Gluten-Free'},
    {'value': 'dairy_free', 'label': 'Dairy-Free'},
    {'value': 'peanut_allergy', 'label': 'Peanut Allergy'},
    {'value': 'nut_allergy', 'label': 'Tree Nut Allergy'},
    {'value': 'halal', 'label': 'Halal'},
    {'value': 'low_sodium', 'label': 'Low Sodium'},
  ];

  // Activity Levels (maps to API 1-5)
  static const Map<String, int> activityLevelMap = {
    'Sedentary': 1,
    'Lightly Active': 2,
    'Moderately Active': 3,
    'Very Active': 4,
    'Extremely Active': 5,
  };

  // Goal Map (maps display to API values)
  static const Map<String, String> goalMap = {
    'Lose Weight': 'lose',
    'Maintain': 'maintain',
    'Gain Muscle': 'gain',
  };
}
