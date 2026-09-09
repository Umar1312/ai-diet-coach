import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:diet_coach_ai/core/constants/app_constants.dart';

abstract interface class RevenueCatClient {
  bool get isConfigured;
  Future<bool> configure();
  void listen(CustomerInfoUpdateListener listener);
  Future<CustomerInfo> identify(String appUserId);
  Future<CustomerInfo> refreshCustomerInfo();
  Future<void> logOut();
  Future<PaywallResult> presentPaywallIfNeeded();
  Future<CustomerInfo> restorePurchases();
  Future<void> presentCustomerCenter();
  void dispose();
}

class RevenueCatService implements RevenueCatClient {
  static const bool _useRevenueCatTestStore = bool.fromEnvironment(
    'USE_REVENUECAT_TEST_STORE',
  );

  bool _isConfigured = false;
  CustomerInfoUpdateListener? _customerInfoListener;

  @override
  bool get isConfigured => _isConfigured;

  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<bool> configure() async {
    if (_isConfigured) return true;
    if (!isSupportedPlatform) return false;

    final apiKey = _apiKey;
    if (apiKey.isEmpty) return false;
    if (!apiKey.startsWith('appl_') && !apiKey.startsWith('test_')) {
      throw const RevenueCatConfigurationException(
        'The iOS RevenueCat public SDK key must start with appl_ or test_.',
      );
    }

    await Purchases.setLogLevel(kReleaseMode ? LogLevel.info : LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _isConfigured = true;
    return true;
  }

  @override
  void listen(CustomerInfoUpdateListener listener) {
    if (!_isConfigured) return;
    final previous = _customerInfoListener;
    if (previous != null) {
      Purchases.removeCustomerInfoUpdateListener(previous);
    }
    _customerInfoListener = listener;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  @override
  Future<CustomerInfo> identify(String appUserId) async {
    _requireConfigured();
    if (appUserId.trim().isEmpty) {
      throw const RevenueCatConfigurationException(
        'RevenueCat requires a non-empty App User ID.',
      );
    }
    final result = await Purchases.logIn(appUserId);
    return result.customerInfo;
  }

  @override
  Future<CustomerInfo> refreshCustomerInfo() async {
    _requireConfigured();
    await Purchases.invalidateCustomerInfoCache();
    return Purchases.getCustomerInfo();
  }

  @override
  Future<void> logOut() async {
    if (!_isConfigured) return;
    final info = await Purchases.getCustomerInfo();
    if (info.originalAppUserId.startsWith(r'$RCAnonymousID:')) return;
    await Purchases.logOut();
  }

  @override
  Future<PaywallResult> presentPaywallIfNeeded() async {
    _requireConfigured();
    return RevenueCatUI.presentPaywallIfNeeded(
      AppConstants.revenueCatEntitlementId,
      displayCloseButton: true,
    );
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    _requireConfigured();
    return Purchases.restorePurchases();
  }

  @override
  Future<void> presentCustomerCenter() async {
    _requireConfigured();
    await RevenueCatUI.presentCustomerCenter();
  }

  @override
  void dispose() {
    final listener = _customerInfoListener;
    if (listener != null && _isConfigured) {
      Purchases.removeCustomerInfoUpdateListener(listener);
    }
    _customerInfoListener = null;
  }

  String get _apiKey {
    if (!kReleaseMode &&
        _useRevenueCatTestStore &&
        AppConstants.revenueCatTestApiKey.trim().isNotEmpty) {
      return AppConstants.revenueCatTestApiKey.trim();
    }
    return AppConstants.revenueCatIosApiKey.trim();
  }

  void _requireConfigured() {
    if (!_isConfigured) {
      throw const RevenueCatConfigurationException(
        'RevenueCat is not configured for this build.',
      );
    }
  }
}

class RevenueCatConfigurationException implements Exception {
  final String message;

  const RevenueCatConfigurationException(this.message);

  @override
  String toString() => message;
}
