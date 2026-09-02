import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show mealCheckInStore;
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

class MealCheckInScreen extends StatefulWidget {
  final String slot;

  const MealCheckInScreen({super.key, required this.slot});

  @override
  State<MealCheckInScreen> createState() => _MealCheckInScreenState();
}

class _MealCheckInScreenState extends State<MealCheckInScreen> {
  @override
  void initState() {
    super.initState();
    mealCheckInStore.prepare(widget.slot);
  }

  void _showMessage(String message, {bool success = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          backgroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.notifications_active_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    final logged = await mealCheckInStore.confirmPlannedMeal();
    if (!mounted || !logged) return;
    context.go('/meal-impact');
  }

  Future<void> _skip() async {
    HapticFeedback.mediumImpact();
    final skipped = await mealCheckInStore.skipPlannedMeal();
    if (!mounted || !skipped) return;
    _showMessage('Meal skipped');
    context.go('/home');
  }

  Future<void> _snooze() async {
    HapticFeedback.selectionClick();
    await mealCheckInStore.snooze();
    if (!mounted) return;
    _showMessage('We’ll check again in 30 minutes', success: false);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final isLoading = mealCheckInStore.isLoading.value;
            final meal = mealCheckInStore.plannedMeal;
            final error = mealCheckInStore.errorMessage.value;
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              );
            }
            if (meal == null) {
              return _UnavailableState(
                message: error,
                onClose: () => context.go('/home'),
              );
            }
            return _CheckInContent(
              meal: meal,
              error: error,
              isSubmitting: mealCheckInStore.isSubmitting.value,
              onConfirm: _confirm,
              onDifferentMeal: () {
                HapticFeedback.selectionClick();
                context.go('/log/text');
              },
              onSnooze: _snooze,
              onSkip: _skip,
              onClose: () => context.go('/home'),
            );
          },
        ),
      ),
    );
  }
}

class _CheckInContent extends StatelessWidget {
  final PlannedMeal meal;
  final String error;
  final bool isSubmitting;
  final VoidCallback onConfirm;
  final VoidCallback onDifferentMeal;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onClose;

  const _CheckInContent({
    required this.meal,
    required this.error,
    required this.isSubmitting,
    required this.onConfirm,
    required this.onDifferentMeal,
    required this.onSnooze,
    required this.onSkip,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isHandled = meal.status != PlannedMealStatus.planned;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 22),
              ),
            ),
          ),
          const Spacer(),
          Text(
            meal.meal.emoji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 24),
          Text(
            isHandled ? 'Already checked in' : 'Did you eat as planned?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            meal.meal.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${meal.meal.calories} cal · ${meal.meal.proteinG}g protein',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          if (error.isNotEmpty) ...[
            _ErrorBanner(message: error),
            const SizedBox(height: 16),
          ],
          if (isHandled)
            _PrimaryButton(
              label: 'Back to today',
              onTap: onClose,
              isLoading: false,
            )
          else ...[
            _PrimaryButton(
              label: 'Yes, I ate this',
              onTap: onConfirm,
              isLoading: isSubmitting,
            ),
            const SizedBox(height: 12),
            _SecondaryButton(
              label: 'I ate something else',
              onTap: isSubmitting ? null : onDifferentMeal,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TextAction(
                    label: 'Not yet',
                    onTap: isSubmitting ? null : onSnooze,
                  ),
                ),
                Expanded(
                  child: _TextAction(
                    label: 'Skipping it',
                    onTap: isSubmitting ? null : onSkip,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.border : AppColors.textPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.textOnPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                  letterSpacing: -0.3,
                ),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _UnavailableState({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            size: 52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 20),
          Text(
            message.isEmpty ? 'This meal is no longer available.' : message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Back to today',
            onTap: onClose,
            isLoading: false,
          ),
        ],
      ),
    );
  }
}
