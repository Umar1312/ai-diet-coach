import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/constants/app_constants.dart';
import 'package:diet_coach_ai/main.dart' show authStore, revenueCatService;

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  var _isLoading = false;
  String? _message;

  Future<void> _openPaywall() async {
    HapticFeedback.mediumImpact();
    if (!revenueCatService.isConfigured) {
      setState(() {
        _message = kDebugMode
            ? 'RevenueCat keys are not set. Add them to .env before release.'
            : 'Purchases are unavailable right now. Please try again later.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await revenueCatService.presentPaywallIfNeeded();
      final active = await revenueCatService.hasActiveEntitlement();
      if (!mounted) return;
      if (active) {
        authStore.markSubscriptionActive();
        context.go('/home');
      } else {
        setState(() => _message = 'No active plan yet.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to open paywall. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    HapticFeedback.selectionClick();
    if (!revenueCatService.isConfigured) {
      setState(() => _message = 'RevenueCat is not configured.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final active = await revenueCatService.restorePurchases();
      if (!mounted) return;
      if (active) {
        authStore.markSubscriptionActive();
        context.go('/home');
      } else {
        setState(() => _message = 'No purchases found to restore.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Restore failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Unlock your plan',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Personalized targets, simple day plans, pantry-aware meals, and adaptive replanning.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              const _FeatureRow(
                icon: Icons.track_changes_rounded,
                label: 'Accurate calorie and macro targets',
              ),
              const _FeatureRow(
                icon: Icons.calendar_today_rounded,
                label: 'Daily plans that fit normal weekdays',
              ),
              const _FeatureRow(
                icon: Icons.kitchen_rounded,
                label: 'Recommendations from food you already have',
              ),
              if (_message != null) ...[
                const SizedBox(height: 24),
                _MessageBanner(message: _message!),
              ],
              const Spacer(),
              GestureDetector(
                onTap: _isLoading ? null : _openPaywall,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? AppColors.border
                        : AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.textOnPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textOnPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _isLoading ? null : _restore,
                child: const SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Center(
                    child: Text(
                      'Restore purchase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              if (kDebugMode && !revenueCatService.isConfigured)
                GestureDetector(
                  onTap: () {
                    authStore.markSubscriptionActive();
                    context.go('/home');
                  },
                  child: const SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: Center(
                      child: Text(
                        'Continue in debug',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${AppConstants.yearlyPrice}/year (${AppConstants.monthlyPrice}/mo)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;

  const _MessageBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
          height: 1.4,
        ),
      ),
    );
  }
}
