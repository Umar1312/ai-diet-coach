import 'user_setup_request.dart';
import 'onboarding_state.dart';

class SessionResponse {
  final String uid;
  final String? email;
  final String? authProvider;
  final bool profileComplete;
  final OnboardingStage onboardingStage;
  final String? pantryDecision;
  final DateTime? onboardingCompletedAt;
  final UserProfile? profile;

  const SessionResponse({
    required this.uid,
    this.email,
    this.authProvider,
    required this.profileComplete,
    required this.onboardingStage,
    this.pantryDecision,
    this.onboardingCompletedAt,
    this.profile,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _fromJson(json);

  static SessionResponse _fromJson(Map<String, dynamic> json) {
    final profileComplete = json['profile_complete'] as bool;
    return SessionResponse(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      authProvider: json['auth_provider'] as String?,
      profileComplete: profileComplete,
      onboardingStage: OnboardingStage.fromString(
        json['onboarding_stage'] as String?,
        profileComplete: profileComplete,
      ),
      pantryDecision: json['pantry_decision'] as String?,
      onboardingCompletedAt: json['onboarding_completed_at'] == null
          ? null
          : DateTime.parse(json['onboarding_completed_at'] as String),
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }
}
