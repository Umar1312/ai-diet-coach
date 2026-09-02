import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../main.dart' show notificationStore, subscriptionStore;
import '../../widgets/onboarding_secondary_button.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _isRequesting = false;

  void _continue(BuildContext context) {
    context.go(
      subscriptionStore.hasAccess.value ? '/home' : '/onboarding/paywall',
    );
  }

  Future<void> _requestNotifications(BuildContext context) async {
    if (_isRequesting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRequesting = true);
    try {
      await notificationStore.setEnabled(true);
      if (context.mounted) _continue(context);
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BackButton(
                            onTap: () =>
                                context.popOrGo('/onboarding/plan-preview'),
                          ),
                          const SizedBox(height: 28),
                          const _NotificationHero(),
                          const SizedBox(height: 28),
                          const _NotificationPreview(),
                          const SizedBox(height: 32),
                          const Text(
                            'Why it helps',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _BenefitsCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _PermissionActions(
              isUpdating: _isRequesting,
              onEnable: () => _requestNotifications(context),
              onNotNow: () {
                HapticFeedback.selectionClick();
                _continue(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _NotificationHero extends StatelessWidget {
  const _NotificationHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.fatsLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.fats,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'A small nudge,\nright when it helps.',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.2,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your plan is easier to follow when you do not have to remember every meal. We use notifications for timely meal check-ins—nothing noisy.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🌞', style: TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Lunch check-in',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              Text(
                '1:00 PM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Did you eat your planned lunch?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Tap to log it, choose something different, or snooze.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPrimary.withValues(alpha: 0.68),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          _BenefitRow(
            icon: Icons.schedule_rounded,
            title: 'Timed to your plan',
            detail: 'Check-ins only appear for meals in your daily plan.',
          ),
          _CardDivider(),
          _BenefitRow(
            icon: Icons.touch_app_rounded,
            title: 'Useful in one tap',
            detail:
                'Log, change, snooze, or skip without hunting through the app.',
          ),
          _CardDivider(),
          _BenefitRow(
            icon: Icons.tune_rounded,
            title: 'Always in your control',
            detail:
                'Change every meal time—or turn reminders off—from Profile.',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 0, thickness: 0.5, color: AppColors.border);
  }
}

class _PermissionActions extends StatelessWidget {
  final bool isUpdating;
  final VoidCallback onEnable;
  final VoidCallback onNotNow;

  const _PermissionActions({
    required this.isUpdating,
    required this.onEnable,
    required this.onNotNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: isUpdating ? null : onEnable,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: isUpdating
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.textOnPrimary,
                            size: 21,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Turn on meal check-ins',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 7),
            OnboardingSecondaryButton(
              text: 'Not now',
              onPressed: isUpdating ? null : onNotNow,
            ),
            const Text(
              'Only meal check-ins. Change this anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
