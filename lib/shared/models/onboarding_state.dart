enum OnboardingStage {
  profileSetup('profile_setup'),
  pantrySetup('pantry_setup'),
  planPreview('plan_preview'),
  complete('complete');

  final String value;
  const OnboardingStage(this.value);

  static OnboardingStage fromString(
    String? value, {
    bool profileComplete = false,
  }) {
    if (value == null) {
      return profileComplete
          ? OnboardingStage.complete
          : OnboardingStage.profileSetup;
    }
    return OnboardingStage.values.firstWhere(
      (stage) => stage.value == value,
      orElse: () => OnboardingStage.profileSetup,
    );
  }
}

class OnboardingStateResponse {
  final OnboardingStage stage;
  final String? pantryDecision;
  final DateTime? completedAt;

  const OnboardingStateResponse({
    required this.stage,
    this.pantryDecision,
    this.completedAt,
  });

  factory OnboardingStateResponse.fromJson(Map<String, dynamic> json) =>
      OnboardingStateResponse(
        stage: OnboardingStage.fromString(json['onboarding_stage'] as String?),
        pantryDecision: json['pantry_decision'] as String?,
        completedAt: json['onboarding_completed_at'] == null
            ? null
            : DateTime.parse(json['onboarding_completed_at'] as String),
      );
}

class OnboardingPantryResponse extends OnboardingStateResponse {
  final int itemsAdded;

  const OnboardingPantryResponse({
    required super.stage,
    super.pantryDecision,
    super.completedAt,
    required this.itemsAdded,
  });

  factory OnboardingPantryResponse.fromJson(Map<String, dynamic> json) {
    final state = OnboardingStateResponse.fromJson(json);
    return OnboardingPantryResponse(
      stage: state.stage,
      pantryDecision: state.pantryDecision,
      completedAt: state.completedAt,
      itemsAdded: json['items_added'] as int,
    );
  }
}
