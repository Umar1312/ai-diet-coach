import 'user_setup_request.dart';

class SessionResponse {
  final String uid;
  final String? email;
  final String? authProvider;
  final bool profileComplete;
  final UserProfile? profile;

  const SessionResponse({
    required this.uid,
    this.email,
    this.authProvider,
    required this.profileComplete,
    this.profile,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      SessionResponse(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        authProvider: json['auth_provider'] as String?,
        profileComplete: json['profile_complete'] as bool,
        profile: json['profile'] != null
            ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
      );
}
