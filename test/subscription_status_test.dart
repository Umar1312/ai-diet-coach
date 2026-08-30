import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/shared/models/subscription_status.dart';

void main() {
  test('subscription status round trips backend contract', () {
    final status = SubscriptionStatus.fromJson({
      'app_user_id': 'firebase-uid-123',
      'entitlement_id': 'pro',
      'is_entitled': true,
      'status': 'trialing',
      'product_id': 'ai_diet_buddy_annual',
      'period_type': 'TRIAL',
      'store': 'app_store',
      'environment': 'SANDBOX',
      'will_renew': true,
      'purchased_at': '2026-08-02T10:00:00Z',
      'expires_at': '2026-08-09T10:00:00Z',
      'synced_at': '2026-08-02T10:00:02Z',
    });

    expect(status.status, SubscriptionState.trialing);
    expect(status.isEntitled, isTrue);
    expect(status.expiresAt, DateTime.utc(2026, 8, 9, 10));
    expect(status.toJson()['status'], 'trialing');
    expect(status.toJson()['entitlement_id'], 'pro');
  });

  test('unknown subscription state falls back to free', () {
    expect(
      SubscriptionState.fromString('future_state'),
      SubscriptionState.free,
    );
  });
}
