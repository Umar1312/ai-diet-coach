import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/router/safe_navigation.dart';
import 'package:diet_coach_ai/features/log_meal/stores/meal_logging_store.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore, mealLoggingStore;
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

class MealLogScreen extends StatefulWidget {
  final DashboardStore? store;
  final MealLoggingStore? loggingStore;
  final bool refreshOnOpen;

  const MealLogScreen({
    super.key,
    this.store,
    this.loggingStore,
    this.refreshOnOpen = true,
  });

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  DashboardStore get _store => widget.store ?? dashboardStore;
  MealLoggingStore get _loggingStore => widget.loggingStore ?? mealLoggingStore;

  @override
  void initState() {
    super.initState();
    _loggingStore.clearError();
    if (widget.refreshOnOpen) unawaited(_store.refresh());
  }

  void _logMeal(PlannedMeal meal) {
    if (_loggingStore.isLogging) return;
    HapticFeedback.mediumImpact();
    unawaited(_loggingStore.logPlannedMeal(meal));
    context.go('/meal-impact');
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
              child: Observer(
                builder: (_) {
                  final meals = _store.plannedMeals.toList()
                    ..sort((a, b) => a.order.compareTo(b.order));
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CloseButton(
                                onTap: () => context.popOrGo('/home'),
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                'What did you eat?',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -1.2,
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Choose a meal from today’s plan. One tap logs it.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const _SectionHeading(),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                      if (_store.isLoading.value && meals.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _PlanLoading(),
                        )
                      else if (meals.isEmpty)
                        SliverToBoxAdapter(
                          child: _NoPlanCard(
                            hasError: _store.hasError.value,
                            onRetry: () => _store.refresh(),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          sliver: SliverList.separated(
                            itemCount: meals.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final meal = meals[index];
                              return _PlannedMealChoice(
                                plannedMeal: meal,
                                isLogging:
                                    _loggingStore.loggingPlanOrder.value ==
                                    meal.order,
                                isBusy: _loggingStore.isLogging,
                                onTap: () => _logMeal(meal),
                              );
                            },
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Observer(
                          builder: (_) {
                            final error = _loggingStore.errorMessage.value;
                            if (error == null) {
                              return const SizedBox(height: 28);
                            }
                            return _ErrorBanner(message: error);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Observer(
              builder: (_) => _SomethingElseAction(
                enabled: !_loggingStore.isLogging,
                onTap: () => context.push('/log/search'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Today’s plan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Text(
          'TAP TO LOG',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textTertiary,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _PlannedMealChoice extends StatelessWidget {
  final PlannedMeal plannedMeal;
  final bool isLogging;
  final bool isBusy;
  final VoidCallback onTap;

  const _PlannedMealChoice({
    required this.plannedMeal,
    required this.isLogging,
    required this.isBusy,
    required this.onTap,
  });

  bool get _canLog => plannedMeal.status == PlannedMealStatus.planned;

  @override
  Widget build(BuildContext context) {
    final meal = plannedMeal.meal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canLog && !isBusy ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _canLog ? 1 : 0.58,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: isLogging
                ? Border.all(color: AppColors.textPrimary, width: 1.2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(meal.emoji, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _slotLabel(plannedMeal.slot),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (plannedMeal.isOptional) ...[
                          const SizedBox(width: 7),
                          const Text(
                            'OPTIONAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbs,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.25,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${meal.calories} cal  ·  ${meal.proteinG}g protein',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _MealStatusIcon(status: plannedMeal.status, loading: isLogging),
            ],
          ),
        ),
      ),
    );
  }

  String _slotLabel(String slot) => switch (slot) {
    'breakfast' => 'BREAKFAST',
    'lunch' => 'LUNCH',
    'snack' => 'SNACK',
    'dinner' => 'DINNER',
    'late' => 'LATE MEAL',
    _ => slot.toUpperCase(),
  };
}

class _MealStatusIcon extends StatelessWidget {
  final PlannedMealStatus status;
  final bool loading;

  const _MealStatusIcon({required this.status, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      );
    }
    if (status == PlannedMealStatus.logged) {
      return Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.proteinLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 19,
          color: AppColors.protein,
        ),
      );
    }
    if (status == PlannedMealStatus.skipped) {
      return const Icon(
        Icons.remove_circle_outline_rounded,
        color: AppColors.textTertiary,
        size: 25,
      );
    }
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
    );
  }
}

class _SomethingElseAction extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SomethingElseAction({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  onTap();
                }
              : null,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: enabled ? AppColors.textPrimary : AppColors.border,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  color: enabled
                      ? AppColors.textOnPrimary
                      : AppColors.textTertiary,
                  size: 22,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    'I ate something else',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppColors.textOnPrimary
                          : AppColors.textTertiary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanLoading extends StatelessWidget {
  const _PlanLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  final bool hasError;
  final VoidCallback onRetry;

  const _NoPlanCard({required this.hasError, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No meals to choose from',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasError
                ? 'We could not load today’s plan.'
                : 'Search for what you ate instead.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Try again',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
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
      margin: const EdgeInsets.fromLTRB(28, 14, 28, 28),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
