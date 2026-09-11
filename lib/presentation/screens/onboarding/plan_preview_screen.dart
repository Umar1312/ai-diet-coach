import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/main.dart' show authStore, dashboardStore;
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

class OnboardingPlanPreviewScreen extends StatefulWidget {
  final bool autoGenerate;

  const OnboardingPlanPreviewScreen({super.key, this.autoGenerate = true});

  @override
  State<OnboardingPlanPreviewScreen> createState() =>
      _OnboardingPlanPreviewScreenState();
}

class _OnboardingPlanPreviewScreenState
    extends State<OnboardingPlanPreviewScreen> {
  bool _isPreparing = true;
  String? _errorMessage;
  bool _isCompleting = false;
  String? _completionError;

  @override
  void initState() {
    super.initState();
    if (widget.autoGenerate) {
      _preparePlan();
    } else {
      _isPreparing = false;
    }
  }

  Future<void> _preparePlan() async {
    setState(() {
      _isPreparing = true;
      _errorMessage = null;
    });

    final didLoad = await dashboardStore.fetchOnboardingPlanPreview();
    if (!mounted) return;

    setState(() {
      _isPreparing = false;
      if (!didLoad || dashboardStore.plannedMeals.isEmpty) {
        _errorMessage = dashboardStore.errorMessage.value.isNotEmpty
            ? dashboardStore.errorMessage.value
            : 'We could not finish your first plan.';
      }
    });
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCompleting = true;
      _completionError = null;
    });
    try {
      await authStore.completeOnboarding();
      if (mounted) context.go('/onboarding/notifications');
    } on ApiException catch (error) {
      if (mounted) setState(() => _completionError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _completionError =
              'We could not save your progress. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _isPreparing
              ? const _BuildingPlanView(key: ValueKey('loading'))
              : _errorMessage != null
              ? _PlanErrorView(
                  key: const ValueKey('error'),
                  message: _errorMessage!,
                  onRetry: _preparePlan,
                )
              : _PlanReadyView(
                  key: const ValueKey('ready'),
                  isCompleting: _isCompleting,
                  completionError: _completionError,
                  onContinue: _completeOnboarding,
                ),
        ),
      ),
    );
  }
}

class _BuildingPlanView extends StatelessWidget {
  const _BuildingPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const _FoodConveyor(),
          const SizedBox(height: 32),
          const Text(
            'Building your day',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Balancing your targets, food preferences, and kitchen staples.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
              strokeWidth: 2.5,
            ),
          ),
          const Spacer(flex: 3),
          const Text(
            'This usually takes a few seconds',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// A light, looping food parade: each ingredient enters from the left,
/// settles over the plate, then continues off the right edge.
class _FoodConveyor extends StatefulWidget {
  const _FoodConveyor();

  @override
  State<_FoodConveyor> createState() => _FoodConveyorState();
}

class _FoodConveyorState extends State<_FoodConveyor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  static const _foods = ['🥑', '🍓', '🥗', '🍗', '🍚', '🥦'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: double.infinity,
      height: 132,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = constraints.maxWidth * .56;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🍽️', style: TextStyle(fontSize: 52)),
                  ),
                  if (!reduceMotion)
                    for (var index = 0; index < 3; index++)
                      _MovingFood(
                        emoji:
                            _foods[(_controller.value * _foods.length + index)
                                    .floor() %
                                _foods.length],
                        progress: (_controller.value + index / 3) % 1,
                        travel: travel,
                        laneOffset: (index - 1) * 18,
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MovingFood extends StatelessWidget {
  const _MovingFood({
    required this.emoji,
    required this.progress,
    required this.travel,
    required this.laneOffset,
  });

  final String emoji;
  final double progress;
  final double travel;
  final double laneOffset;

  @override
  Widget build(BuildContext context) {
    // 0–.42: arrive with a small overshoot; .42–.58: settle at the plate;
    // .58–1: glide away. The opacity keeps entering/exiting food subtle.
    final x = switch (progress) {
      < .42 =>
        -travel + (travel + 10) * Curves.easeOutBack.transform(progress / .42),
      < .58 => 10 * (1 - Curves.easeOut.transform((progress - .42) / .16)),
      _ => travel * Curves.easeIn.transform((progress - .58) / .42),
    };
    final scale = progress < .42
        ? .72 + .28 * Curves.easeOut.transform(progress / .42)
        : 1.0;
    final opacity = progress < .08
        ? progress / .08
        : progress > .9
        ? (1 - progress) / .1
        : 1.0;
    return Transform.translate(
      offset: Offset(x, laneOffset),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0, 1),
          child: Text(emoji, style: const TextStyle(fontSize: 36)),
        ),
      ),
    );
  }
}

class _PlanReadyView extends StatelessWidget {
  final VoidCallback onContinue;
  final bool isCompleting;
  final String? completionError;

  const _PlanReadyView({
    super.key,
    required this.onContinue,
    required this.isCompleting,
    this.completionError,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final meals = dashboardStore.plannedMeals.toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        final usedPantry = authStore.pantryDecision.value == 'selected';

        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.textPrimary,
                                  size: 21,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.proteinLight,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: AppColors.protein,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'PLAN READY',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.protein,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Your first day,\nhandled.',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -1.2,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            usedPantry
                                ? 'Built around your goals and the kitchen staples you selected.'
                                : 'Built around your goals and food preferences. Add pantry items anytime.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _MacroSummary(
                            calories: dashboardStore.targetCalories.value,
                            protein: dashboardStore.targetProtein.value,
                            carbs: dashboardStore.targetCarbs.value,
                            fats: dashboardStore.targetFats.value,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Text(
                                'On the menu',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${meals.length} meals',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    sliver: SliverList.separated(
                      itemCount: meals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _MealPreviewCard(
                        plannedMeal: meals[index],
                        accent: _mealAccent(index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (completionError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.caloriesLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                completionError!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    GestureDetector(
                      onTap: isCompleting ? null : onContinue,
                      child: Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: isCompleting
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator.adaptive(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnPrimary,
                                  ),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Looks good',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textOnPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.textOnPrimary,
                                    size: 21,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Nothing is locked in — swap meals whenever you like.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _mealAccent(int index) {
    const colors = [
      AppColors.carbsLight,
      AppColors.proteinLight,
      AppColors.fatsLight,
      AppColors.caloriesLight,
    ];
    return colors[index % colors.length];
  }
}

class _MacroSummary extends StatelessWidget {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  const _MacroSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR DAILY TARGET',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$calories',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.3,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 3),
                child: Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MacroItem(
                  color: AppColors.protein,
                  value: '${protein}g',
                  label: 'Protein',
                ),
              ),
              Expanded(
                child: _MacroItem(
                  color: AppColors.carbs,
                  value: '${carbs}g',
                  label: 'Carbs',
                ),
              ),
              Expanded(
                child: _MacroItem(
                  color: AppColors.fats,
                  value: '${fats}g',
                  label: 'Fats',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final Color color;
  final String value;
  final String label;

  const _MacroItem({
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MealPreviewCard extends StatelessWidget {
  final PlannedMeal plannedMeal;
  final Color accent;

  const _MealPreviewCard({required this.plannedMeal, required this.accent});

  String get _slotLabel {
    if (plannedMeal.slot.isEmpty) return 'Meal';
    return plannedMeal.slot[0].toUpperCase() + plannedMeal.slot.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final meal = plannedMeal.meal;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(meal.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _slotLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.7,
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
                const SizedBox(height: 3),
                Text(
                  meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${meal.calories} kcal  ·  ${meal.proteinG}g protein${meal.prepMinutes > 0 ? '  ·  ${meal.prepMinutes} min' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
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

class _PlanErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PlanErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.caloriesLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.error,
              size: 38,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Your plan needs\none more try',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Try again',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
