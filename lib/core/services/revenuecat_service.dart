import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:diet_coach_ai/core/constants/app_constants.dart';

class RevenueCatService {
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  Future<void> configure() async {
    final apiKey = _platformApiKey;
    if (apiKey.isEmpty || _isConfigured) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));
    _isConfigured = true;
  }

  Future<void> identify(String appUserId) async {
    if (!_isConfigured || appUserId.isEmpty) return;
    await Purchases.logIn(appUserId);
  }

  Future<void> logOut() async {
    if (!_isConfigured) return;
    await Purchases.logOut();
  }

  Future<bool> hasActiveEntitlement() async {
    if (!_isConfigured) return false;
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(
      AppConstants.revenueCatEntitlementId,
    );
  }

  Future<bool> restorePurchases() async {
    if (!_isConfigured) return false;
    await Purchases.restorePurchases();
    return hasActiveEntitlement();
  }

  Future<dynamic> presentPaywall() async {
    if (!_isConfigured) return null;
    return RevenueCatUI.presentPaywall();
  }

  Future<dynamic> presentPaywallIfNeeded() async {
    if (!_isConfigured) return null;
    return RevenueCatUI.presentPaywallIfNeeded(
      AppConstants.revenueCatEntitlementId,
    );
  }

  String get _platformApiKey {
    if (Platform.isIOS || Platform.isMacOS) {
      return AppConstants.revenueCatIosApiKey.trim();
    }
    if (Platform.isAndroid) {
      return AppConstants.revenueCatAndroidApiKey.trim();
    }
    return '';
  }
}
