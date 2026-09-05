import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/nextmeal_app_icon.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 36).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Introduction(),
                        SizedBox(height: 56),
                        _ExampleDay(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const _WelcomeActions(),
          ],
        ),
      ),
    );
  }
}

class _Introduction extends StatelessWidget {
  const _Introduction();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const NextMealAppIcon(size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Meal plans that\nchange with\nyour day.',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -1.2,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Get a daily meal plan built around your goals, the food you have, and flavours you enjoy.',
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

/// A static illustration of the product promise, never a live recommendation.
class _ExampleDay extends StatelessWidget {
  const _ExampleDay();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AND WHEN YOUR DAY CHANGES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 18),
        _ExampleStep(
          icon: Icons.restaurant_rounded,
          title: 'You ate out for lunch',
          detail: 'Log what you actually ate.',
        ),
        Padding(
          padding: EdgeInsets.only(left: 19),
          child: SizedBox(
            height: 30,
            child: VerticalDivider(
              width: 1,
              thickness: 1.5,
              color: AppColors.protein,
            ),
          ),
        ),
        _ExampleStep(
          icon: Icons.auto_awesome_rounded,
          iconColor: AppColors.protein,
          iconBackground: AppColors.proteinLight,
          title: 'Dinner adjusts to your day',
          detail: 'Turkey sandwich with salad',
          footnote: 'Uses what you already have',
        ),
        SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Review the change. Keep what works.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExampleStep extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String detail;
  final String? footnote;

  const _ExampleStep({
    required this.icon,
    this.iconColor = AppColors.textSecondary,
    this.iconBackground = AppColors.surface,
    required this.title,
    required this.detail,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: ExcludeSemantics(
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: footnote == null
                      ? FontWeight.w400
                      : FontWeight.w600,
                  color: footnote == null
                      ? AppColors.textSecondary
                      : AppColors.protein,
                  height: 1.4,
                ),
              ),
              if (footnote != null) ...[
                const SizedBox(height: 3),
                Text(
                  footnote!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions();

  void _openLogin(BuildContext context, {required bool isPrimary}) {
    if (isPrimary) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openLogin(context, isPrimary: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                minimumSize: const Size(0, 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              child: const Row(
                children: [
                  Expanded(child: Text('Build my plan')),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
