import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobx/mobx.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/di/providers.dart';
import '../../features/subscription/stores/subscription_store.dart';
import '../../shared/models/onboarding_state.dart';
import '../../shared/models/session_response.dart';

/// Authentication status used by the router to decide where to route.
enum AuthStatus {
  unknown,
  unauthenticated,
  needsOnboarding,
  needsSubscription,
  authenticated,
}

/// Manual MobX store (no codegen) for the full Firebase auth lifecycle.
///
/// Apple Sign In  -> Firebase OAuthProvider("apple.com")
/// Google Sign In -> Firebase GoogleAuthProvider
///
/// After a successful Firebase sign-in the store fetches /auth/session from
/// the backend to learn whether the user has already finished onboarding.
class AuthStore {
  final SubscriptionStore subscriptionStore;

  AuthStore({required this.subscriptionStore}) {
    _subscriptionReaction = reaction<bool>(
      (_) => subscriptionStore.hasAccess.value,
      (hasAccess) {
        if (onboardingStage.value != OnboardingStage.complete) return;
        runInAction(() {
          status.value = hasAccess
              ? AuthStatus.authenticated
              : AuthStatus.needsSubscription;
        });
      },
    );
  }

  // ── Observables ────────────────────────────────────────────────────────

  final status = Observable<AuthStatus>(AuthStatus.unknown);
  final firebaseUser = Observable<User?>(null);
  final isLoading = Observable<bool>(false);
  final errorMessage = Observable<String?>(null);
  final isProfileComplete = Observable<bool>(false);
  final onboardingStage = Observable<OnboardingStage>(
    OnboardingStage.profileSetup,
  );
  final pantryDecision = Observable<String?>(null);

  // ── Computed ───────────────────────────────────────────────────────────

  late final isAuthenticated = Computed<bool>(
    () => status.value == AuthStatus.authenticated,
  );

  static AuthStatus statusForOnboardingStage(
    OnboardingStage stage, {
    required bool hasSubscriptionAccess,
  }) {
    if (stage != OnboardingStage.complete) return AuthStatus.needsOnboarding;
    return hasSubscriptionAccess
        ? AuthStatus.authenticated
        : AuthStatus.needsSubscription;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  StreamSubscription<User?>? _sub;
  late final ReactionDisposer _subscriptionReaction;

  /// Call AFTER Firebase.initializeApp() succeeds. Binds the authStateChanges
  /// stream so sign-in / sign-out events drive [status].
  void init() {
    _sub?.cancel();
    _useFirebaseTokenProvider();
    _sub = FirebaseAuth.instance.idTokenChanges().listen(_onAuthChanged);
  }

  /// Dev-mode bypass: skip Firebase, set a backend token directly and resolve
  /// onboarding status from /auth/session.
  Future<void> setDevToken(String token) async {
    apiService.setAuthTokenProvider(null);
    apiService.setAuthToken(token);
    await _syncSession();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      // Clear any previous account's routing state before resolving this
      // user's durable onboarding stage from the backend.
      runInAction(() {
        firebaseUser.value = user;
        status.value = AuthStatus.unknown;
        isProfileComplete.value = false;
        onboardingStage.value = OnboardingStage.profileSetup;
        pantryDecision.value = null;
      });
      await _syncTokenAndSession(user);
    } else {
      runInAction(() {
        firebaseUser.value = null;
        status.value = AuthStatus.unauthenticated;
        isProfileComplete.value = false;
        onboardingStage.value = OnboardingStage.profileSetup;
        pantryDecision.value = null;
      });
      apiService.setAuthToken('');
    }
  }

  Future<void> _syncTokenAndSession(User user) async {
    try {
      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw FirebaseAuthException(code: 'no-token');
      }
      apiService.setAuthToken(idToken);
      await _syncSession();
    } catch (e) {
      debugPrint('AuthStore: token sync failed -> $e');
      runInAction(() {
        errorMessage.value = 'Unable to reach the server. Please try again.';
        status.value = AuthStatus.needsOnboarding;
      });
    }
  }

  Future<SessionResponse> _syncSession() async {
    try {
      final session = await apiService.fetchSession();
      final hasSubscriptionAccess = await subscriptionStore.identify(
        session.uid,
      );
      runInAction(() {
        isProfileComplete.value = session.profileComplete;
        onboardingStage.value = session.onboardingStage;
        pantryDecision.value = session.pantryDecision;
        status.value = statusForOnboardingStage(
          session.onboardingStage,
          hasSubscriptionAccess: hasSubscriptionAccess,
        );
        errorMessage.value = null;
      });
      return session;
    } catch (e) {
      debugPrint('AuthStore: session sync failed -> $e');
      runInAction(() {
        errorMessage.value = e is ApiException
            ? e.message
            : 'Unable to reach the server. Please try again.';
        status.value = AuthStatus.needsOnboarding;
      });
      rethrow;
    }
  }

  // ── Actions: Sign in with Apple ─────────────────────────────────────────

  Future<void> signInWithApple() async {
    runInAction(() {
      isLoading.value = true;
      errorMessage.value = null;
    });
    try {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );
      await _syncTokenAndSession(userCredential.user!);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        runInAction(() => errorMessage.value = _appleErrorMessage(e));
      }
    } on FirebaseAuthException catch (e) {
      runInAction(() => errorMessage.value = _firebaseErrorMessage(e));
    } catch (e) {
      runInAction(
        () => errorMessage.value = 'Apple Sign In failed. Try again.',
      );
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  // ── Actions: Sign in with Google ────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    runInAction(() {
      isLoading.value = true;
      errorMessage.value = null;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the flow
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _syncTokenAndSession(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      runInAction(() => errorMessage.value = _firebaseErrorMessage(e));
    } catch (e) {
      runInAction(
        () => errorMessage.value = 'Google Sign In failed. Please try again.',
      );
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  // ── Actions: Sign out ───────────────────────────────────────────────────

  Future<void> signOut() async {
    runInAction(() {
      isLoading.value = true;
      errorMessage.value = null;
    });
    try {
      await subscriptionStore.logOut();
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      apiService.setAuthToken('');
      runInAction(() {
        firebaseUser.value = null;
        status.value = AuthStatus.unauthenticated;
        isProfileComplete.value = false;
        onboardingStage.value = OnboardingStage.profileSetup;
        pantryDecision.value = null;
      });
    } catch (e) {
      runInAction(() => errorMessage.value = 'Sign out failed.');
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  /// Clears authentication and subscription state after the backend has
  /// permanently deleted the account. Cleanup errors are intentionally
  /// ignored: the deletion has already completed server-side.
  Future<void> finishAccountDeletion() async {
    try {
      await subscriptionStore.logOut();
    } catch (e) {
      debugPrint('AuthStore: RevenueCat logout after deletion failed -> $e');
    }
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('AuthStore: Google logout after deletion failed -> $e');
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('AuthStore: Firebase logout after deletion failed -> $e');
    }

    apiService.setAuthToken('');
    runInAction(() {
      firebaseUser.value = null;
      status.value = AuthStatus.unauthenticated;
      isProfileComplete.value = false;
      onboardingStage.value = OnboardingStage.profileSetup;
      pantryDecision.value = null;
      errorMessage.value = null;
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Keeps local routing aligned immediately after /users/setup succeeds.
  void markProfileSetupComplete() {
    runInAction(() {
      isProfileComplete.value = true;
      onboardingStage.value = OnboardingStage.pantrySetup;
      pantryDecision.value = null;
      status.value = AuthStatus.needsOnboarding;
    });
  }

  void markPantrySetupComplete({required bool skipped}) {
    runInAction(() {
      onboardingStage.value = OnboardingStage.planPreview;
      pantryDecision.value = skipped ? 'skipped' : 'selected';
      status.value = AuthStatus.needsOnboarding;
    });
  }

  Future<void> completeOnboarding() async {
    final response = await apiService.completeOnboarding();
    if (response.stage != OnboardingStage.complete) {
      throw ApiException(
        code: 'invalid_onboarding_state',
        message: 'Onboarding did not complete. Please try again.',
      );
    }
    runInAction(() {
      isProfileComplete.value = true;
      onboardingStage.value = OnboardingStage.complete;
      pantryDecision.value = response.pantryDecision;
      status.value = subscriptionStore.hasAccess.value
          ? AuthStatus.authenticated
          : AuthStatus.needsSubscription;
    });
  }

  void markSubscriptionActive() {
    runInAction(() {
      if (onboardingStage.value == OnboardingStage.complete &&
          subscriptionStore.hasAccess.value) {
        status.value = AuthStatus.authenticated;
      }
    });
  }

  void markUnauthenticated() {
    runInAction(() {
      firebaseUser.value = null;
      isProfileComplete.value = false;
      onboardingStage.value = OnboardingStage.profileSetup;
      pantryDecision.value = null;
      status.value = AuthStatus.unauthenticated;
    });
    apiService.setAuthToken('');
  }

  void clearError() {
    runInAction(() => errorMessage.value = null);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _subscriptionReaction();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  Future<String?> _currentFirebaseIdToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    firebaseUser.value = user;
    return user.getIdToken(forceRefresh);
  }

  void _useFirebaseTokenProvider() {
    apiService.setAuthTokenProvider(_currentFirebaseIdToken);
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid credentials. Please try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _appleErrorMessage(SignInWithAppleAuthorizationException e) {
    switch (e.code) {
      case AuthorizationErrorCode.notHandled:
      case AuthorizationErrorCode.failed:
        return 'Apple Sign In failed. Please try again.';
      case AuthorizationErrorCode.invalidResponse:
        return 'Apple Sign In returned an unexpected response.';
      case AuthorizationErrorCode.notInteractive:
        return 'Apple Sign In is not available in this context.';
      case AuthorizationErrorCode.unknown:
        return 'Apple Sign In could not complete.';
      case AuthorizationErrorCode.canceled:
        return 'Apple Sign In was canceled.';
    }
  }
}
