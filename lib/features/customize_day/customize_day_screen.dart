import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show customizeDayStore, dashboardStore;
import 'widgets/slot_meal_picker_sheet.dart';

class CustomizeDayScreen extends StatefulWidget {
  const CustomizeDayScreen({super.key});

  @override
  State<CustomizeDayScreen> createState() => _CustomizeDayScreenState();
}

class _CustomizeDayScreenState extends State<CustomizeDayScreen> {
  @override
  void initState() {
    super.initState();
    customizeDayStore.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const _MacroCounter(),
                    const SizedBox(height: 24),
                    for (var i = 0; i < 5; i++) ...[
                      _SlotCard(order: i),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 10),
      child: Row(
        children: [
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
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize day',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Build your own 5-slot plan.',
                  style: TextStyle(
                    fontSize: 15,
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

class _MacroCounter extends StatelessWidget {
  const _MacroCounter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Observer(
            builder: (_) {
              return _MacroBar(
                label: 'Calories',
                consumed: customizeDayStore.totalCalories.value,
                target: dashboardStore.targetCalories.value,
                unit: 'kcal',
                color: AppColors.calories,
                progress: customizeDayStore.caloriesProgress.value,
              );
            },
          ),
          const SizedBox(height: 12),
          Observer(
            builder: (_) {
              return _MacroBar(
                label: 'Protein',
                consumed: customizeDayStore.totalProtein.value,
                target: dashboardStore.targetProtein.value,
                unit: 'g',
                color: AppColors.protein,
                progress: customizeDayStore.proteinProgress.value,
              );
            },
          ),
          const SizedBox(height: 12),
          Observer(
            builder: (_) {
              return _MacroBar(
                label: 'Carbs',
                consumed: customizeDayStore.totalCarbs.value,
                target: dashboardStore.targetCarbs.value,
                unit: 'g',
                color: AppColors.carbs,
                progress: customizeDayStore.carbsProgress.value,
              );
            },
          ),
          const SizedBox(height: 12),
          Observer(
            builder: (_) {
              return _MacroBar(
                label: 'Fats',
                consumed: customizeDayStore.totalFats.value,
                target: dashboardStore.targetFats.value,
                unit: 'g',
                color: AppColors.fats,
                progress: customizeDayStore.fatsProgress.value,
              );
            },
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
  final double progress;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
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

class _SlotCard extends StatelessWidget {
  final int order;

  const _SlotCard({required this.order});

  String get _slotLabel {
    switch (order) {
      case 0:
        return 'Breakfast';
      case 1:
        return 'Lunch';
      case 2:
        return 'Dinner';
      case 3:
        return 'Snack';
      case 4:
        return 'Late';
      default:
        return 'Meal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final meal = customizeDayStore.meals[order];
        final hasMeal = meal != null;

        return GestureDetector(
          onTap: () => _onTap(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasMeal ? AppColors.surface : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasMeal ? AppColors.border : AppColors.surface,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        hasMeal
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child:
                        hasMeal
                            ? Text(meal.emoji, style: const TextStyle(fontSize: 24))
                            : const Icon(
                              Icons.add_rounded,
                              color: AppColors.textTertiary,
                              size: 24,
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _slotLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasMeal ? meal.name : 'Add meal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color:
                              hasMeal
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (hasMeal) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${meal.calories} cal · ${meal.proteinG}g P · ${meal.carbsG}g C · ${meal.fatsG}g F',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasMeal)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      customizeDayStore.clearSlot(order);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTap(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final result = await showSlotMealPickerSheet(context);
    if (result != null && context.mounted) {
      customizeDayStore.setMealFromPantry(order, result);
    }
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Observer(
          builder: (_) {
            final canSave = customizeDayStore.canSave.value;
            final isSaving = customizeDayStore.isSaving.value;
            final error = customizeDayStore.errorMessage.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null && error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error,
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
                GestureDetector(
                  onTap:
                      canSave && !isSaving
                          ? () async {
                            HapticFeedback.mediumImpact();
                            await customizeDayStore.save();
                            if (context.mounted &&
                                (customizeDayStore.errorMessage.value?.isEmpty ?? true)) {
                              context.go('/plan');
                            }
                          }
                          : null,
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: canSave ? AppColors.textPrimary : AppColors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child:
                        isSaving
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Save Custom Day',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
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
