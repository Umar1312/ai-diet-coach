import 'package:flutter/material.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show authStore, subscriptionStore;

/// Checks Pro access at the moment a premium action is requested.
///
/// Existing subscribers continue immediately. Free users see the native
/// RevenueCat paywall and continue only when an entitlement becomes active.
Future<bool> requireProAccess(BuildContext context) async {
  final hadAccess = subscriptionStore.hasAccess.value;
  final activated = await subscriptionStore.requestAccess();
  if (!context.mounted) return false;

  if (activated) {
    authStore.markSubscriptionActive();
    if (!hadAccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(_accessActivatedSnackBar());
    }
    return true;
  }

  final message = subscriptionStore.errorMessage.value;
  if (message != null && message.isNotEmpty) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_accessErrorSnackBar(message));
  }
  return false;
}

SnackBar _accessActivatedSnackBar() {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    backgroundColor: AppColors.textPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    duration: const Duration(seconds: 2),
    content: const Row(
      children: [
        Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
        SizedBox(width: 10),
        Text(
          'Welcome to Pro!',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
      ],
    ),
  );
}

SnackBar _accessErrorSnackBar(String message) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    backgroundColor: AppColors.error,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Text(
      message,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      ),
    ),
  );
}
