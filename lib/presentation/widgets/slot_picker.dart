import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

const extraMealChoice = '__extra__';

/// Shows a bottom sheet asking "Which meal is this?"
/// Returns the selected slot string, or null if "None / Off-plan" is chosen.
Future<String?> showSlotPicker(
  BuildContext context,
  Iterable<PlannedMeal> plannedMeals,
) async {
  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _SlotPickerSheet(
      plannedMeals: plannedMeals
          .where((meal) => meal.status == PlannedMealStatus.planned)
          .toList(),
    ),
  );
}

class _SlotPickerSheet extends StatelessWidget {
  final List<PlannedMeal> plannedMeals;

  const _SlotPickerSheet({required this.plannedMeals});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Which meal is this?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the planned meal it replaced, or mark it as something extra.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          for (final meal in plannedMeals) ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context, meal.id);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text(
                  '${meal.meal.emoji} ${_slotLabel(meal.slot)} · ${meal.meal.name}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, extraMealChoice);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Something extra',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _slotLabel(String slot) =>
      '${slot[0].toUpperCase()}${slot.substring(1)}';
}
