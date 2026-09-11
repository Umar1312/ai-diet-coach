import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show authStore, subscriptionStore;
import 'package:diet_coach_ai/shared/widgets/legal_footer.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  Future<void> _openPaywall(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final activated = await subscriptionStore.presentPaywall();
    if (!context.mounted || !activated) return;

    authStore.markSubscriptionActive();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_successSnackBar('Welcome to Pro!'));
    context.go('/home');
  }

  Future<void> _restore(BuildContext context) async {
    HapticFeedback.selectionClick();
    final activated = await subscriptionStore.restorePurchases();
    if (!context.mounted || !activated) return;

    authStore.markSubscriptionActive();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_successSnackBar('Purchase restored'));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final isLoading = subscriptionStore.isLoading.value;
            final message = subscriptionStore.errorMessage.value;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: isLoading ? null : () => _close(context),
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
                              'Know what to\neat next',
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
                              'Get a practical day plan that stays aligned with your goals as you log meals.',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const _FeatureRow(
                              icon: Icons.restaurant_menu_rounded,
                              label: 'A clear next meal throughout your day',
                            ),
                            const _FeatureRow(
                              icon: Icons.sync_rounded,
                              label:
                                  'A plan that adapts when real life changes',
                            ),
                            const _FeatureRow(
                              icon: Icons.edit_note_rounded,
                              label: 'Fast meal logging in your own words',
                            ),
                            if (message != null && message.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _MessageBanner(message: message),
                            ],
                            const Spacer(),
                            GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => _openPaywall(context),
                              child: Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: isLoading
                                      ? AppColors.border
                                      : AppColors.textPrimary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CircularProgressIndicator.adaptive(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.textOnPrimary,
                                                  ),
                                              strokeWidth: 2.5,
                                            ),
                                      )
                                    : const Text(
                                        'View plans',
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
                              onTap: isLoading ? null : () => _restore(context),
                              child: const SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: Center(
                                  child: Text(
                                    'Restore purchases',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const LegalFooter(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
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
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

SnackBar _successSnackBar(String message) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    backgroundColor: AppColors.textPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    duration: const Duration(seconds: 2),
    content: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success),
        const SizedBox(width: 12),
        Text(
          message,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
