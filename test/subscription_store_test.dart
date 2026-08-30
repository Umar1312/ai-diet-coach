import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/core/services/revenuecat_service.dart';
import 'package:diet_coach_ai/features/subscription/stores/subscription_store.dart';
import 'package:diet_coach_ai/shared/models/subscription_status.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
BASE_URL=http://localhost
REVENUECAT_ENTITLEMENT_ID=pro
''',
    );
  });

  test(
    'initialization remains safely gated when RevenueCat is unavailable',
    () async {
      final client = _FakeRevenueCatClient(configured: false);
      final store = SubscriptionStore(
        revenueCatService: client,
        apiService: _FakeApiService(),
      );

      await store.initialize();

      expect(store.isConfigured.value, isFalse);
      expect(store.hasAccess.value, isFalse);
      expect(await store.presentPaywall(), isFalse);
      expect(
        store.errorMessage.value,
        'Subscriptions are unavailable right now.',
      );
    },
  );

  test('initialization recognizes an active trial entitlement', () async {
    final client = _FakeRevenueCatClient(
      configured: true,
      customerInfo: _customerInfo(periodType: PeriodType.trial),
    );
    final store = SubscriptionStore(
      revenueCatService: client,
      apiService: _FakeApiService(),
    );

    await store.initialize();

    expect(store.isConfigured.value, isTrue);
    expect(store.state.value, SubscriptionState.trialing);
    expect(store.hasAccess.value, isTrue);
    expect(store.productId.value, 'ai_diet_buddy_annual');
    expect(store.expiresAt.value, DateTime.utc(2026, 8, 15));
  });

  test('request access skips the paywall for an active entitlement', () async {
    final client = _FakeRevenueCatClient(
      configured: true,
      customerInfo: _customerInfo(periodType: PeriodType.normal),
    );
    final store = SubscriptionStore(
      revenueCatService: client,
      apiService: _FakeApiService(),
    );
    await store.initialize();

    expect(await store.requestAccess(), isTrue);
    expect(client.paywallPresentationCount, 0);
  });

  test('request access presents the paywall for a free user', () async {
    final client = _FakeRevenueCatClient(configured: true);
    final store = SubscriptionStore(
      revenueCatService: client,
      apiService: _FakeApiService(),
    );
    await store.initialize();

    expect(await store.requestAccess(), isFalse);
    expect(client.paywallPresentationCount, 1);
  });

  test('a completed paywall refreshes access and syncs the backend', () async {
    final client = _FakeRevenueCatClient(
      configured: true,
      customerInfo: _customerInfo(),
      paywallResult: PaywallResult.purchased,
    );
    final apiService = _FakeApiService();
    final store = SubscriptionStore(
      revenueCatService: client,
      apiService: apiService,
    );
    await store.initialize();
    client.customerInfo = _customerInfo(periodType: PeriodType.normal);

    final activated = await store.requestAccess();

    expect(activated, isTrue);
    expect(store.state.value, SubscriptionState.active);
    expect(store.hasAccess.value, isTrue);
    expect(apiService.syncCount, 1);
  });

  test(
    'billing issues retain access while surfacing the account state',
    () async {
      final client = _FakeRevenueCatClient(
        configured: true,
        customerInfo: _customerInfo(
          periodType: PeriodType.normal,
          billingIssueDetectedAt: '2026-08-08T08:00:00Z',
        ),
      );
      final store = SubscriptionStore(
        revenueCatService: client,
        apiService: _FakeApiService(),
      );

      await store.initialize();

      expect(store.state.value, SubscriptionState.billingIssue);
      expect(store.hasAccess.value, isTrue);
      expect(store.displayStatus, 'Payment issue');
    },
  );
}

class _FakeRevenueCatClient implements RevenueCatClient {
  _FakeRevenueCatClient({
    required this.configured,
    CustomerInfo? customerInfo,
    this.paywallResult = PaywallResult.cancelled,
  }) : customerInfo = customerInfo ?? _customerInfo();

  final bool configured;
  CustomerInfo customerInfo;
  final PaywallResult paywallResult;
  CustomerInfoUpdateListener? listener;
  int paywallPresentationCount = 0;

  @override
  bool get isConfigured => configured;

  @override
  Future<bool> configure() async => configured;

  @override
  void listen(CustomerInfoUpdateListener listener) {
    this.listener = listener;
  }

  @override
  Future<CustomerInfo> identify(String appUserId) async => customerInfo;

  @override
  Future<CustomerInfo> refreshCustomerInfo() async => customerInfo;

  @override
  Future<void> logOut() async {}

  @override
  Future<PaywallResult> presentPaywallIfNeeded() async {
    paywallPresentationCount++;
    return paywallResult;
  }

  @override
  Future<CustomerInfo> restorePurchases() async => customerInfo;

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  void dispose() {}
}

class _FakeApiService extends ApiService {
  _FakeApiService() : super(Dio());

  int syncCount = 0;

  @override
  Future<SubscriptionStatus> syncSubscriptionStatus() async {
    syncCount++;
    return SubscriptionStatus(
      appUserId: 'test-user',
      entitlementId: AppConstants.revenueCatEntitlementId,
      isEntitled: true,
      status: SubscriptionState.active,
      willRenew: true,
      syncedAt: DateTime.utc(2026, 8, 8),
    );
  }
}

CustomerInfo _customerInfo({
  PeriodType? periodType,
  String? billingIssueDetectedAt,
}) {
  final entitlement = periodType == null
      ? null
      : EntitlementInfo(
          AppConstants.revenueCatEntitlementId,
          true,
          true,
          '2026-08-08T08:00:00Z',
          '2026-08-08T08:00:00Z',
          'ai_diet_buddy_annual',
          true,
          store: Store.appStore,
          periodType: periodType,
          expirationDate: '2026-08-15T00:00:00Z',
          billingIssueDetectedAt: billingIssueDetectedAt,
        );
  final active = entitlement == null
      ? const <String, EntitlementInfo>{}
      : <String, EntitlementInfo>{
          AppConstants.revenueCatEntitlementId: entitlement,
        };

  return CustomerInfo(
    EntitlementInfos(active, active),
    const {},
    const [],
    const [],
    const [],
    '2026-08-08T08:00:00Z',
    r'$RCAnonymousID:test-user',
    const {},
    '2026-08-08T08:00:00Z',
  );
}
