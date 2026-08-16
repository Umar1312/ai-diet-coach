import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/core/services/revenuecat_service.dart';
import 'package:diet_coach_ai/shared/models/subscription_status.dart';

class SubscriptionStore {
  final RevenueCatClient _revenueCatService;
  final ApiService _apiService;

  SubscriptionStore({
    required RevenueCatClient revenueCatService,
    required ApiService apiService,
  }) : _revenueCatService = revenueCatService,
       _apiService = apiService;

  final isConfigured = Observable<bool>(false);
  final isLoading = Observable<bool>(false);
  final state = Observable<SubscriptionState>(SubscriptionState.free);
  final productId = Observable<String?>(null);
  final expiresAt = Observable<DateTime?>(null);
  final errorMessage = Observable<String?>(null);

  late final hasAccess = Computed<bool>(
    () => switch (state.value) {
      SubscriptionState.trialing ||
      SubscriptionState.active ||
      SubscriptionState.gracePeriod ||
      SubscriptionState.billingIssue => true,
      SubscriptionState.free || SubscriptionState.expired => false,
    },
  );

  String get displayStatus {
    return switch (state.value) {
      SubscriptionState.trialing => 'Free trial',
      SubscriptionState.active => 'Pro',
      SubscriptionState.gracePeriod => 'Pro · grace period',
      SubscriptionState.billingIssue => 'Payment issue',
      SubscriptionState.expired => 'Expired',
      SubscriptionState.free => 'Free',
    };
  }

  Future<void> initialize() async {
    try {
      final configured = await _revenueCatService.configure();
      runInAction(() => isConfigured.value = configured);
      if (!configured) return;
      _revenueCatService.listen(_applyCustomerInfo);
      _applyCustomerInfo(await _revenueCatService.refreshCustomerInfo());
    } catch (error) {
      debugPrint('SubscriptionStore: RevenueCat setup failed -> $error');
      runInAction(() {
        isConfigured.value = false;
        errorMessage.value = 'Subscriptions are unavailable right now.';
      });
    }
  }

  Future<bool> identify(String appUserId) async {
    if (!isConfigured.value) return false;
    try {
      final info = await _revenueCatService.identify(appUserId);
      _applyCustomerInfo(info);
      // Reconcile on every identified launch. This keeps the backend's
      // entitlement gate current even when a webhook was delayed or missed.
      await _syncBackend();
      return hasAccess.value;
    } catch (error) {
      debugPrint('SubscriptionStore: identity sync failed -> $error');
      runInAction(
        () => errorMessage.value = 'Unable to check your subscription.',
      );
      return false;
    }
  }

  Future<bool> presentPaywall() async {
    if (!isConfigured.value) {
      runInAction(
        () => errorMessage.value = 'Subscriptions are unavailable right now.',
      );
      return false;
    }

    runInAction(() {
      isLoading.value = true;
      errorMessage.value = null;
    });
    try {
      final result = await _revenueCatService.presentPaywallIfNeeded();
      if (result == PaywallResult.error) {
        runInAction(
          () => errorMessage.value = 'Unable to complete the purchase.',
        );
        return false;
      }
      if (result == PaywallResult.cancelled) return false;

      _applyCustomerInfo(await _revenueCatService.refreshCustomerInfo());
      if (hasAccess.value) await _syncBackend();
      return hasAccess.value;
    } on PlatformException catch (error) {
      debugPrint('SubscriptionStore: paywall failed -> $error');
      runInAction(() => errorMessage.value = _purchaseErrorMessage(error));
      return false;
    } catch (error) {
      debugPrint('SubscriptionStore: paywall failed -> $error');
      runInAction(
        () => errorMessage.value = 'Unable to open the paywall. Try again.',
      );
      return false;
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  /// Returns immediately for an active entitlement, otherwise presents the
  /// RevenueCat paywall and resolves with the resulting access state.
  Future<bool> requestAccess() async {
    if (hasAccess.value) return true;
    return presentPaywall();
  }

  Future<bool> restorePurchases() async {
    if (!isConfigured.value) {
      runInAction(
        () => errorMessage.value = 'Subscriptions are unavailable right now.',
      );
      return false;
    }

    runInAction(() {
      isLoading.value = true;
      errorMessage.value = null;
    });
    try {
      _applyCustomerInfo(await _revenueCatService.restorePurchases());
      if (hasAccess.value) {
        await _syncBackend();
        return true;
      }
      runInAction(() => errorMessage.value = 'No active purchase was found.');
      return false;
    } catch (error) {
      debugPrint('SubscriptionStore: restore failed -> $error');
      runInAction(
        () => errorMessage.value = 'Restore failed. Please try again.',
      );
      return false;
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  Future<void> manageSubscription() async {
    if (!isConfigured.value) {
      runInAction(
        () => errorMessage.value = 'Subscriptions are unavailable right now.',
      );
      return;
    }
    try {
      await _revenueCatService.presentCustomerCenter();
      _applyCustomerInfo(await _revenueCatService.refreshCustomerInfo());
      if (hasAccess.value) await _syncBackend();
    } catch (error) {
      debugPrint('SubscriptionStore: customer center failed -> $error');
      runInAction(
        () => errorMessage.value = 'Unable to manage your subscription.',
      );
    }
  }

  Future<void> logOut() async {
    try {
      await _revenueCatService.logOut();
    } catch (error) {
      debugPrint('SubscriptionStore: logout failed -> $error');
    } finally {
      runInAction(() {
        state.value = SubscriptionState.free;
        productId.value = null;
        expiresAt.value = null;
        errorMessage.value = null;
      });
    }
  }

  void clearError() => runInAction(() => errorMessage.value = null);

  void dispose() => _revenueCatService.dispose();

  void _applyCustomerInfo(CustomerInfo info) {
    final entitlement =
        info.entitlements.active[AppConstants.revenueCatEntitlementId];
    runInAction(() {
      if (entitlement == null) {
        state.value = SubscriptionState.free;
        productId.value = null;
        expiresAt.value = null;
        return;
      }

      if (entitlement.billingIssueDetectedAt != null) {
        state.value = SubscriptionState.billingIssue;
      } else if (entitlement.periodType == PeriodType.trial) {
        state.value = SubscriptionState.trialing;
      } else {
        state.value = SubscriptionState.active;
      }
      productId.value = entitlement.productIdentifier;
      expiresAt.value = entitlement.expirationDate == null
          ? null
          : DateTime.tryParse(entitlement.expirationDate!);
      errorMessage.value = null;
    });
  }

  Future<void> _syncBackend() async {
    try {
      await _apiService.syncSubscriptionStatus();
    } catch (error) {
      // The SDK entitlement is immediately authoritative for the app UI.
      // Webhooks will reconcile the backend if this recovery call is delayed.
      debugPrint('SubscriptionStore: backend reconciliation failed -> $error');
    }
  }

  String _purchaseErrorMessage(PlatformException error) {
    final code = PurchasesErrorHelper.getErrorCode(error);
    return switch (code) {
      PurchasesErrorCode.purchaseCancelledError => '',
      PurchasesErrorCode.productNotAvailableForPurchaseError =>
        'This subscription is not available for purchase.',
      PurchasesErrorCode.paymentPendingError =>
        'Your purchase is pending approval.',
      _ => 'Unable to complete the purchase. Please try again.',
    };
  }
}
