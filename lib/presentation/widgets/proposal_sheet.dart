import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

/// Shows when the user logs an off-plan meal and the backend returns a
/// pending_proposal. The user can accept, reject+regenerate, or dismiss.
class ProposalSheet extends StatelessWidget {
  const ProposalSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final proposal = dashboardStore.pendingProposal.value;
        if (proposal == null) return const SizedBox.shrink();

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
          child: SafeArea(
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.protein.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_rounded,
                        color: AppColors.protein,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Plan Adjustment Suggested',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  proposal.reason,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                if (proposal.changedSlots.isNotEmpty)
                  const Text(
                    'Updated meals',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.2,
                    ),
                  ),
                const SizedBox(height: 10),
                for (final slot in proposal.changedSlots)
                  _ChangedSlotRow(slot: slot),
                const SizedBox(height: 28),
                Observer(
                  builder: (_) {
                    final isLoading = dashboardStore.isGeneratingPlan.value;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  try {
                                    await dashboardStore.acceptProposal();
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (_) {
                                    // Error handled in store; modal stays open
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLoading)
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  isLoading ? 'Applying...' : 'Accept Changes',
                                  style: const TextStyle(
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
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () async {
                                  HapticFeedback.selectionClick();
                                  await dashboardStore
                                      .rejectAndRegenerateProposal();
                                  // Modal stays open in case a new proposal arrives
                                },
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                isLoading
                                    ? 'Generating...'
                                    : 'Try Something Else',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () async {
                                  HapticFeedback.selectionClick();
                                  try {
                                    await dashboardStore.dismissProposal();
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (_) {
                                    // Error handled in store; modal stays open
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Dismiss',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChangedSlotRow extends StatelessWidget {
  final PlannedMeal slot;
  const _ChangedSlotRow({required this.slot});

  String get _slotLabel {
    switch (slot.slot) {
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
        return slot.slot[0].toUpperCase() + slot.slot.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = slot.meal.name.isEmpty && slot.meal.calories == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          if (!isEmpty)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  slot.meal.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ),
          const SizedBox(width: 12),
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
                  isEmpty ? 'Removed' : slot.meal.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isEmpty
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!isEmpty)
            Text(
              '${slot.meal.calories} cal',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.calories,
              ),
            ),
        ],
      ),
    );
  }
}
