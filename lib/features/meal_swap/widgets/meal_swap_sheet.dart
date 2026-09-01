import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/features/customize_day/widgets/slot_meal_picker_sheet.dart';
import 'package:diet_coach_ai/features/meal_swap/models/meal_swap_models.dart';
import 'package:diet_coach_ai/main.dart' show mealSwapStore;
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

enum MealSwapOutcome { updated, proposalCreated }

Future<MealSwapOutcome?> showMealSwapSheet(
  BuildContext context, {
  required PlannedMeal plannedMeal,
}) {
  return showModalBottomSheet<MealSwapOutcome>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MealSwapSheet(plannedMeal: plannedMeal),
  );
}

class _MealSwapSheet extends StatefulWidget {
  final PlannedMeal plannedMeal;

  const _MealSwapSheet({required this.plannedMeal});

  @override
  State<_MealSwapSheet> createState() => _MealSwapSheetState();
}

class _MealSwapSheetState extends State<_MealSwapSheet> {
  @override
  void initState() {
    super.initState();
    unawaited(mealSwapStore.begin(widget.plannedMeal));
  }

  @override
  void dispose() {
    mealSwapStore.reset();
    super.dispose();
  }

  Future<void> _chooseMyOwn() async {
    HapticFeedback.selectionClick();
    final component = await showSlotMealPickerSheet(context);
    if (!mounted || component == null) return;
    mealSwapStore.selectMeal(
      Meal(
        name: component.name,
        emoji: component.emoji,
        calories: component.totalCalories,
        proteinG: component.totalProteinG,
        carbsG: component.totalCarbsG,
        fatsG: component.totalFatsG,
        servingSize: component.servingSize,
        components: [component],
      ),
    );
  }

  Future<void> _apply({required bool rebalance}) async {
    HapticFeedback.mediumImpact();
    final response = await mealSwapStore.applySelection(
      rebalanceRemaining: rebalance,
    );
    if (!mounted || response == null) return;
    Navigator.of(context).pop(
      response.requiresConfirmation
          ? MealSwapOutcome.proposalCreated
          : MealSwapOutcome.updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Observer(
          builder: (_) {
            final selection = mealSwapStore.selectedMeal.value;
            return Column(
              children: [
                const _SheetHandle(),
                if (selection == null)
                  Expanded(
                    child: _AlternativesView(
                      current: widget.plannedMeal,
                      onChooseMyOwn: _chooseMyOwn,
                    ),
                  )
                else
                  Expanded(
                    child: _ReviewView(
                      current: widget.plannedMeal.meal,
                      replacement: selection,
                      onBack: mealSwapStore.clearSelection,
                      onApply: _apply,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _AlternativesView extends StatelessWidget {
  final PlannedMeal current;
  final VoidCallback onChooseMyOwn;

  const _AlternativesView({required this.current, required this.onChooseMyOwn});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change this meal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Alternatives for ${current.meal.name} that still fit your day.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            itemCount: MealSwapReason.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final reason = MealSwapReason.values[index];
              return Observer(
                builder: (_) => _ReasonChip(
                  reason: reason,
                  selected: mealSwapStore.selectedReason.value == reason,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Observer(
            builder: (_) {
              if (mealSwapStore.isLoading.value) {
                return const _LoadingAlternatives();
              }
              final error = mealSwapStore.errorMessage.value;
              if (error != null && mealSwapStore.alternatives.isEmpty) {
                return _AlternativesError(message: error);
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                children: [
                  for (
                    var index = 0;
                    index < mealSwapStore.alternatives.length;
                    index++
                  ) ...[
                    _AlternativeCard(
                      alternative: mealSwapStore.alternatives[index],
                      isBestFit: index == 0,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ChooseOwnCard(onTap: onChooseMyOwn),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    _InlineError(message: error),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final MealSwapReason reason;
  final bool selected;

  const _ReasonChip({required this.reason, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        unawaited(mealSwapStore.chooseReason(reason));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          reason.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  final MealAlternative alternative;
  final bool isBestFit;

  const _AlternativeCard({required this.alternative, required this.isBestFit});

  @override
  Widget build(BuildContext context) {
    final meal = alternative.meal;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        mealSwapStore.selectMeal(meal);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isBestFit
                ? AppColors.protein.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isBestFit)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'BEST FIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.protein,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alternative.whyItFits,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallPill(label: '${meal.calories} cal'),
                _SmallPill(label: '${meal.proteinG}g protein'),
                if (meal.prepMinutes > 0)
                  _SmallPill(label: '${meal.prepMinutes} min'),
                if (alternative.usedPantryItems.isNotEmpty)
                  const _SmallPill(
                    label: 'Uses your pantry',
                    highlighted: true,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${_signed(alternative.calorieDelta)} cal  ·  ${_signed(alternative.proteinDelta)}g protein vs current',
              style: const TextStyle(
                fontSize: 12,
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

class _ChooseOwnCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ChooseOwnCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            _RoundIcon(icon: Icons.add_rounded),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose my own',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Search a food or describe it for an AI estimate.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  final Meal current;
  final Meal replacement;
  final VoidCallback onBack;
  final Future<void> Function({required bool rebalance}) onApply;

  const _ReviewView({
    required this.current,
    required this.replacement,
    required this.onBack,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final calorieDelta = replacement.calories - current.calories;
    final proteinDelta = replacement.proteinG - current.proteinG;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const _RoundIcon(icon: Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Review your change',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            children: [
              _MealComparisonCard(label: 'CURRENT MEAL', meal: current),
              const _SwapConnector(),
              _MealComparisonCard(
                label: 'NEW MEAL',
                meal: replacement,
                highlighted: true,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.protein.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_fix_high_rounded,
                      color: AppColors.protein,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keep today on track',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'We’ll adjust only your later meals if needed. Meals you’ve logged stay unchanged.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ChangeChip(
                                icon: Icons.local_fire_department_outlined,
                                label: _calorieChangeLabel(calorieDelta),
                              ),
                              _ChangeChip(
                                icon: Icons.fitness_center_rounded,
                                label: _proteinChangeLabel(proteinDelta),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Observer(
                builder: (_) {
                  final error = mealSwapStore.errorMessage.value;
                  return error == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _InlineError(message: error),
                        );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Observer(
            builder: (_) {
              final loading = mealSwapStore.isApplying.value;
              return Column(
                children: [
                  GestureDetector(
                    onTap: loading ? null : () => onApply(rebalance: true),
                    child: _ActionButton(
                      label: loading
                          ? 'Checking your day...'
                          : 'Replace and rebalance my day',
                      detail: loading ? null : 'Later meals may be adjusted',
                      loading: loading,
                      primary: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: loading ? null : () => onApply(rebalance: false),
                    child: const _ActionButton(
                      label: 'Replace without rebalancing',
                      detail: 'All other meals stay unchanged',
                      loading: false,
                      primary: false,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SwapConnector extends StatelessWidget {
  const _SwapConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const SizedBox(width: 38),
          Container(width: 2, height: 54, color: AppColors.border),
          Transform.translate(
            offset: const Offset(-19, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.background, width: 3),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    color: AppColors.textOnPrimary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'REPLACE WITH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnPrimary,
                      letterSpacing: 0.6,
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

class _ChangeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChangeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.protein.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.protein),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealComparisonCard extends StatelessWidget {
  final String label;
  final Meal meal;
  final bool highlighted;

  const _MealComparisonCard({
    required this.label,
    required this.meal,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(meal.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.calories} cal · ${meal.proteinG}g protein',
                  style: const TextStyle(
                    fontSize: 13,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final String? detail;
  final bool loading;
  final bool primary;

  const _ActionButton({
    required this.label,
    this.detail,
    required this.loading,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: detail == null ? (primary ? 64 : 54) : (primary ? 72 : 66),
      decoration: BoxDecoration(
        color: primary ? AppColors.textPrimary : AppColors.surface,
        borderRadius: BorderRadius.circular(primary ? 20 : 18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: primary ? 16 : 15,
                    fontWeight: FontWeight.w700,
                    color: primary ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary
                          ? Colors.white.withValues(alpha: 0.68)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _calorieChangeLabel(int delta) {
  if (delta == 0) return 'Same calories';
  final amount = delta.abs();
  return delta > 0 ? '$amount more calories' : '$amount fewer calories';
}

String _proteinChangeLabel(int delta) {
  if (delta == 0) return 'Same protein';
  final amount = delta.abs();
  return delta > 0 ? '${amount}g more protein' : '${amount}g less protein';
}

class _LoadingAlternatives extends StatelessWidget {
  const _LoadingAlternatives();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.textPrimary,
          ),
          SizedBox(height: 16),
          Text(
            'Finding meals that fit your day...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativesError extends StatelessWidget {
  final String message;

  const _AlternativesError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _InlineError(message: message),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: mealSwapStore.loadAlternatives,
            child: const Text(
              'Try again',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

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
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
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

class _SmallPill extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _SmallPill({required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.protein.withValues(alpha: 0.12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: highlighted ? AppColors.protein : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;

  const _RoundIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 21),
    );
  }
}

String _signed(int value) => value > 0 ? '+$value' : '$value';
