import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  @override
  void initState() {
    super.initState();
    dashboardStore.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Observer(
          builder: (_) {
            final store = dashboardStore;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(child: _PlanActions(store: store)),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(child: _SectionLabel('Today so far')),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      for (final log in store.todayMeals)
                        _LoggedMealRow(
                          name: log.meal.name,
                          calories: log.meal.calories,
                          protein: log.meal.proteinG,
                        ),
                      if (store.todayMeals.isEmpty)
                        const _EmptyState('No meals logged yet'),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                const SliverToBoxAdapter(child: _SectionLabel('Your day')),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (store.plannedMeals.isEmpty &&
                          store.isGeneratingPlan.value)
                        const _LoadingDayPlan()
                      else if (store.plannedMeals.isEmpty)
                        const _GenerateDayPrompt()
                      else
                        for (final meal in store.plannedMeals)
                          _PlannedMealCard(
                            plannedMeal: meal,
                            isSwapping:
                                store.isSwappingSlot.value == meal.order,
                          ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                const SliverToBoxAdapter(
                  child: _SectionLabel("Today's budget"),
                ),
                SliverToBoxAdapter(child: _MacroBudget(store: store)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Your plan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Proactive daily menu tailored to your goals.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Plan Actions (Regenerate)
// ═══════════════════════════════════════════════════════════════════════════

class _PlanActions extends StatelessWidget {
  final DashboardStore store;
  const _PlanActions({required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.plannedMeals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          store.regenerateDayPlan();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Regenerate day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Generate Day Prompt
// ═══════════════════════════════════════════════════════════════════════════

class _GenerateDayPrompt extends StatelessWidget {
  const _GenerateDayPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.textTertiary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No plan for today yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Let the AI build your full-day menu in one tap.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              dashboardStore.fetchDayPlan();
            },
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Generate My Day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Loading Day Plan
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingDayPlan extends StatelessWidget {
  const _LoadingDayPlan();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cooking up your day plan...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Planned Meal Card
// ═══════════════════════════════════════════════════════════════════════════

class _PlannedMealCard extends StatelessWidget {
  final PlannedMeal plannedMeal;
  final bool isSwapping;

  const _PlannedMealCard({required this.plannedMeal, required this.isSwapping});

  String get _slotLabel {
    switch (plannedMeal.slot) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      case 'late':
        return 'Late';
      default:
        return plannedMeal.slot[0].toUpperCase() +
            plannedMeal.slot.substring(1);
    }
  }

  Color get _statusColor {
    switch (plannedMeal.status) {
      case PlannedMealStatus.logged:
        return AppColors.success;
      case PlannedMealStatus.skipped:
        return AppColors.textTertiary;
      case PlannedMealStatus.planned:
        return AppColors.protein;
    }
  }

  String get _statusLabel {
    switch (plannedMeal.status) {
      case PlannedMealStatus.logged:
        return 'Logged';
      case PlannedMealStatus.skipped:
        return 'Skipped';
      case PlannedMealStatus.planned:
        return 'Planned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone =
        plannedMeal.status == PlannedMealStatus.logged ||
        plannedMeal.status == PlannedMealStatus.skipped;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.surface.withValues(alpha: 0.6)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.surface2
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    plannedMeal.meal.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _slotLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plannedMeal.meal.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroPill(
                label: '${plannedMeal.meal.calories} cal',
                color: AppColors.calories,
                isDimmed: isDone,
              ),
              const SizedBox(width: 8),
              _MacroPill(
                label: '${plannedMeal.meal.proteinG}g P',
                color: AppColors.protein,
                isDimmed: isDone,
              ),
              const SizedBox(width: 8),
              _MacroPill(
                label: '${plannedMeal.meal.carbsG}g C',
                color: AppColors.carbs,
                isDimmed: isDone,
              ),
              const SizedBox(width: 8),
              _MacroPill(
                label: '${plannedMeal.meal.fatsG}g F',
                color: AppColors.fats,
                isDimmed: isDone,
              ),
            ],
          ),
          if (!isDone) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isSwapping
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            dashboardStore.swapSlot(plannedMeal.order);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSwapping)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            isSwapping ? 'Swapping...' : 'Swap',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showLogSlotConfirmation(context, plannedMeal);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppColors.textOnPrimary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Log',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showLogSlotConfirmation(BuildContext context, PlannedMeal meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LogSlotConfirmSheet(plannedMeal: meal),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Log Slot Confirmation Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _LogSlotConfirmSheet extends StatelessWidget {
  final PlannedMeal plannedMeal;

  const _LogSlotConfirmSheet({required this.plannedMeal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Text(plannedMeal.meal.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            plannedMeal.meal.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plannedMeal.meal.calories} cal · ${plannedMeal.meal.proteinG}g protein · ${plannedMeal.meal.carbsG}g carbs · ${plannedMeal.meal.fatsG}g fats',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              await dashboardStore.addMeal(
                plannedMeal.meal,
                source: 'recommendation',
                slot: plannedMeal.slot,
              );
              if (context.mounted) {
                _showLoggedSnack(context);
              }
            },
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Yes, I ate this",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoggedSnack(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          backgroundColor: AppColors.textPrimary,
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Logged!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Macro Pill
// ═══════════════════════════════════════════════════════════════════════════

class _MacroPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDimmed;

  const _MacroPill({
    required this.label,
    required this.color,
    required this.isDimmed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDimmed ? AppColors.surface2 : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDimmed ? AppColors.textTertiary : color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Macro Budget
// ═══════════════════════════════════════════════════════════════════════════

class _MacroBudget extends StatelessWidget {
  final DashboardStore store;
  const _MacroBudget({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MacroBar(
            label: 'Calories',
            consumed: store.consumedCalories.value,
            target: store.targetCalories.value,
            unit: 'kcal',
            color: AppColors.calories,
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Protein',
            consumed: store.consumedProtein.value,
            target: store.targetProtein.value,
            unit: 'g',
            color: AppColors.protein,
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Carbs',
            consumed: store.consumedCarbs.value,
            target: store.targetCarbs.value,
            unit: 'g',
            color: AppColors.carbs,
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Fats',
            consumed: store.consumedFats.value,
            target: store.targetFats.value,
            unit: 'g',
            color: AppColors.fats,
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final String unit;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Text(
              '$consumed / $target $unit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section Label
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Logged Meal Row
// ═══════════════════════════════════════════════════════════════════════════

class _LoggedMealRow extends StatelessWidget {
  final String name;
  final int calories;
  final int protein;

  const _LoggedMealRow({
    required this.name,
    required this.calories,
    required this.protein,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            '$calories cal',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.calories,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${protein}g P',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.protein,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
