import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/core/router/app_router.dart';
import 'package:diet_coach_ai/shared/models/onboarding_state.dart';
import 'package:diet_coach_ai/stores/auth_store.dart';

void main() {
  test('logged-out users see welcome before login', () {
    expect(
      AppRouter.redirectForAuthStatus(AuthStatus.unauthenticated, '/splash'),
      '/',
    );
    expect(
      AppRouter.redirectForAuthStatus(AuthStatus.unauthenticated, '/'),
      isNull,
    );
    expect(
      AppRouter.redirectForAuthStatus(AuthStatus.unauthenticated, '/login'),
      isNull,
    );
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.unauthenticated,
        '/onboarding/gender',
      ),
      '/',
    );
  });

  test('newly authenticated users continue from login to profile setup', () {
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsOnboarding,
        '/login',
        onboardingStage: OnboardingStage.profileSetup,
      ),
      '/onboarding/gender',
    );
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsOnboarding,
        '/',
        onboardingStage: OnboardingStage.profileSetup,
      ),
      '/onboarding/gender',
    );
  });

  test('completed users cannot reopen pantry onboarding', () {
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.authenticated,
        '/onboarding/pantry',
        onboardingStage: OnboardingStage.complete,
      ),
      '/home',
    );
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsSubscription,
        '/pantry/onboarding',
        onboardingStage: OnboardingStage.complete,
        isOnboardingPantryPicker: true,
      ),
      '/home',
    );
  });

  test('completed users can still open the regular pantry picker', () {
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.authenticated,
        '/pantry/onboarding',
        onboardingStage: OnboardingStage.complete,
      ),
      isNull,
    );
  });

  test('stale pantry routes resume the persisted onboarding stage', () {
    expect(
      AppRouter.redirectForAuthStatus(
        AuthStatus.needsOnboarding,
        '/pantry/onboarding',
        onboardingStage: OnboardingStage.planPreview,
        isOnboardingPantryPicker: true,
      ),
      '/onboarding/plan-preview',
    );
  });
}
