import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/features/log_meal/stores/meal_logging_store.dart';
import 'package:diet_coach_ai/features/subscription/subscription_gate.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore, mealLoggingStore;
import 'package:diet_coach_ai/shared/models/meal_log_item.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

enum _ImpactAction { accepting, regenerating, keeping }

class MealImpactScreen extends StatefulWidget {
  final DashboardStore? store;
  final MealLoggingStore? loggingStore;

  const MealImpactScreen({super.key, this.store, this.loggingStore});

  @override
  State<MealImpactScreen> createState() => _MealImpactScreenState();
}

class _MealImpactScreenState extends State<MealImpactScreen> {
  _ImpactAction? _activeAction;
  String? _errorMessage;

  DashboardStore get _store => widget.store ?? dashboardStore;
  MealLoggingStore get _loggingStore => widget.loggingStore ?? mealLoggingStore;

  Future<bool> _unlockAdaptation() async {
    return requireProAccess(context);
  }

  Future<void> _acceptChanges() async {
    if (_activeAction != null) return;
    setState(() {
      _activeAction = _ImpactAction.accepting;
      _errorMessage = null;
    });
    final unlocked = await _unlockAdaptation();
    if (!mounted) return;
    if (!unlocked) {
      setState(() => _activeAction = null);
      return;
    }
    try {
      await _store.acceptProposal();
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = _store.errorMessage.value.isNotEmpty
              ? _store.errorMessage.value
              : 'We could not update your plan. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _tryAnother() async {
    if (_activeAction != null) return;
    setState(() {
      _activeAction = _ImpactAction.regenerating;
      _errorMessage = null;
    });
    final unlocked = await _unlockAdaptation();
    if (!mounted) return;
    if (!unlocked) {
      setState(() => _activeAction = null);
      return;
    }
    await _store.rejectAndRegenerateProposal();
    if (!mounted) return;
    setState(() {
      _activeAction = null;
      if (_store.errorMessage.value.isNotEmpty) {
        _errorMessage = _store.errorMessage.value;
      }
    });
  }

  Future<void> _keepOriginal() async {
    if (_activeAction != null) return;
    setState(() {
      _activeAction = _ImpactAction.keeping;
      _errorMessage = null;
    });
    try {
      await _store.dismissProposal();
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = _store.errorMessage.value.isNotEmpty
              ? _store.errorMessage.value
              : 'We could not keep your original plan. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Observer(
          builder: (_) {
            if (_loggingStore.isLogging) {
              return _MealImpactLoading(
                mealName: _loggingStore.pendingMealName.value,
                mealEmoji: _loggingStore.pendingMealEmoji.value,
                onLeave: () => context.go('/home'),
              );
            }

            final loggedMeal = _store.lastLoggedMeal.value;
            if (loggedMeal == null) {
              final logError = _loggingStore.errorMessage.value;
              if (logError != null && _loggingStore.canRetry) {
                return _MealLogFailure(
                  message: logError,
                  onRetry: () {
                    HapticFeedback.mediumImpact();
                    unawaited(_loggingStore.retryLastLog());
                  },
                  onBack: () => context.go('/log'),
                );
              }
              return _MissingImpact(onClose: () => context.go('/home'));
            }

            final proposal = _store.pendingProposal.value;
            final changes = proposal == null
                ? const <_MealChange>[]
                : _meaningfulChanges(
                    current: _store.plannedMeals,
                    proposed: proposal.changedSlots,
                  );
            final hasAdjustment = proposal != null && changes.isNotEmpty;
            final isOverTarget =
                _store.consumedCalories.value > _store.targetCalories.value;

            return Column(
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
                              _ImpactHeader(
                                onClose: _activeAction != null
                                    ? () {}
                                    : proposal == null
                                    ? () => context.go('/home')
                                    : _keepOriginal,
                              ),
                              const SizedBox(height: 28),
                              _HeroMessage(
                                hasAdjustment: hasAdjustment,
                                isOverTarget: isOverTarget,
                              ),
                              const SizedBox(height: 24),
                              _LoggedMealCard(loggedMeal: loggedMeal),
                              const SizedBox(height: 14),
                              _RemainingCard(store: _store),
                              const SizedBox(height: 32),
                              if (hasAdjustment) ...[
                                _AdjustmentIntro(reason: proposal.reason),
                                const SizedBox(height: 16),
                                for (final change in changes) ...[
                                  _MealChangeCard(change: change),
                                  const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 4),
                                const _NotAppliedNote(),
                              ] else
                                _NoAdjustmentCard(
                                  store: _store,
                                  isOverTarget: isOverTarget,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _ImpactActions(
                  hasAdjustment: hasAdjustment,
                  activeAction: _activeAction,
                  errorMessage: _errorMessage,
                  onAccept: _acceptChanges,
                  onTryAnother: _tryAnother,
                  onKeepOriginal: proposal == null
                      ? () => context.go('/home')
                      : _keepOriginal,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_MealChange> _meaningfulChanges({
    required Iterable<PlannedMeal> current,
    required Iterable<PlannedMeal> proposed,
  }) {
    final currentByOrder = {for (final meal in current) meal.order: meal};
    return proposed
        .where((candidate) {
          final existing = currentByOrder[candidate.order];
          if (existing == null) return true;
          return existing.meal.name != candidate.meal.name ||
              existing.meal.calories != candidate.meal.calories ||
              existing.meal.proteinG != candidate.meal.proteinG ||
              existing.meal.carbsG != candidate.meal.carbsG ||
              existing.meal.fatsG != candidate.meal.fatsG;
        })
        .map(
          (candidate) => _MealChange(
            current: currentByOrder[candidate.order],
            proposed: candidate,
          ),
        )
        .toList()
      ..sort((a, b) => a.proposed.order.compareTo(b.proposed.order));
  }
}

class _ImpactHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _ImpactHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.proteinLight,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: AppColors.protein, size: 16),
              SizedBox(width: 5),
              Text(
                'MEAL LOGGED',
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
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onClose();
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
        ),
      ],
    );
  }
}

class _HeroMessage extends StatelessWidget {
  final bool hasAdjustment;
  final bool isOverTarget;

  const _HeroMessage({required this.hasAdjustment, required this.isOverTarget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasAdjustment
              ? 'Your day can\nstill work.'
              : isOverTarget
              ? 'Logged—no\njudgment.'
              : 'You’re still\non track.',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.2,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hasAdjustment
              ? 'Real life happened. Here’s a practical update for the meals you have left.'
              : isOverTarget
              ? 'You’re beyond today’s target, but one meal does not define your progress.'
              : 'Your meal is accounted for and the rest of today still fits.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LoggedMealCard extends StatelessWidget {
  final MealLogItem loggedMeal;

  const _LoggedMealCard({required this.loggedMeal});

  @override
  Widget build(BuildContext context) {
    final meal = loggedMeal.meal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(meal.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _LoggedMacro('${meal.calories} cal'),
                    _LoggedMacro('${meal.proteinG}g protein'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoggedMacro extends StatelessWidget {
  final String label;

  const _LoggedMacro(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary.withValues(alpha: 0.65),
      ),
    );
  }
}

class _RemainingCard extends StatelessWidget {
  final DashboardStore store;

  const _RemainingCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final caloriesLeft =
        store.targetCalories.value - store.consumedCalories.value;
    final proteinLeft = store.targetProtein.value - store.consumedProtein.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RemainingMetric(
              label: caloriesLeft >= 0 ? 'CALORIES LEFT' : 'OVER TARGET',
              value: '${caloriesLeft.abs()}',
              unit: 'cal',
              color: caloriesLeft >= 0 ? AppColors.calories : AppColors.error,
            ),
          ),
          Container(width: 0.5, height: 48, color: AppColors.border),
          const SizedBox(width: 20),
          Expanded(
            child: _RemainingMetric(
              label: proteinLeft > 0 ? 'PROTEIN LEFT' : 'PROTEIN MET',
              value: proteinLeft > 0 ? '$proteinLeft' : '✓',
              unit: proteinLeft > 0 ? 'g' : '',
              color: AppColors.protein,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _RemainingMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textTertiary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AdjustmentIntro extends StatelessWidget {
  final String reason;

  const _AdjustmentIntro({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Suggested adjustment',
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
        const SizedBox(height: 10),
        Text(
          reason,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _MealChange {
  final PlannedMeal? current;
  final PlannedMeal proposed;

  const _MealChange({required this.current, required this.proposed});
}

class _MealChangeCard extends StatelessWidget {
  final _MealChange change;

  const _MealChangeCard({required this.change});

  @override
  Widget build(BuildContext context) {
    final current = change.current;
    final proposed = change.proposed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _slotLabel(proposed.slot).toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _MealOption(
                  eyebrow: 'CURRENT',
                  meal: current,
                  dimmed: true,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: _MealOption(
                  eyebrow: 'SUGGESTED',
                  meal: proposed,
                  dimmed: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _slotLabel(String slot) => switch (slot) {
    'breakfast' => 'Breakfast',
    'lunch' => 'Lunch',
    'snack' => 'Snack',
    'dinner' => 'Dinner',
    'late' => 'Late meal',
    _ => slot,
  };
}

class _MealOption extends StatelessWidget {
  final String eyebrow;
  final PlannedMeal? meal;
  final bool dimmed;

  const _MealOption({
    required this.eyebrow,
    required this.meal,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final isRemoved =
        meal == null || (meal!.meal.name.isEmpty && meal!.meal.calories == 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: dimmed ? AppColors.textTertiary : AppColors.protein,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isRemoved ? 'No meal' : '${meal!.meal.emoji} ${meal!.meal.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: dimmed ? AppColors.textSecondary : AppColors.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isRemoved ? '—' : '${meal!.meal.calories} cal',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: dimmed ? AppColors.textTertiary : AppColors.calories,
          ),
        ),
      ],
    );
  }
}

class _NotAppliedNote extends StatelessWidget {
  const _NotAppliedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fatsLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.fats, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nothing changes until you approve it.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAdjustmentCard extends StatelessWidget {
  final DashboardStore store;
  final bool isOverTarget;

  const _NoAdjustmentCard({required this.store, required this.isOverTarget});

  @override
  Widget build(BuildContext context) {
    final nextMeal = store.nextMeal.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.proteinLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.protein,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverTarget ? 'Your plan is unchanged' : 'No changes needed',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isOverTarget
                      ? 'Finish today normally and focus on your next good choice—no compensation required.'
                      : nextMeal == null
                      ? 'Everything is accounted for. Keep listening to your body.'
                      : 'Your next planned meal is ${nextMeal.emoji} ${nextMeal.name}.',
                  style: const TextStyle(
                    fontSize: 14,
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

class _ImpactActions extends StatelessWidget {
  final bool hasAdjustment;
  final _ImpactAction? activeAction;
  final String? errorMessage;
  final VoidCallback onAccept;
  final VoidCallback onTryAnother;
  final VoidCallback onKeepOriginal;

  const _ImpactActions({
    required this.hasAdjustment,
    required this.activeAction,
    required this.errorMessage,
    required this.onAccept,
    required this.onTryAnother,
    required this.onKeepOriginal,
  });

  bool get _isBusy => activeAction != null;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.caloriesLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: _isBusy
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      hasAdjustment ? onAccept() : onKeepOriginal();
                    },
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child:
                    activeAction == _ImpactAction.accepting ||
                        (!hasAdjustment && _isBusy)
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasAdjustment ? 'Update my day' : 'Back to today',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.textOnPrimary,
                            size: 21,
                          ),
                        ],
                      ),
              ),
            ),
            if (hasAdjustment) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isBusy
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onTryAnother();
                      },
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Center(
                    child: activeAction == _ImpactAction.regenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.textSecondary,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text(
                            'Try another adjustment',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isBusy
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onKeepOriginal();
                      },
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: Center(
                    child: activeAction == _ImpactAction.keeping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.textTertiary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Keep my original plan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealImpactLoading extends StatelessWidget {
  final String? mealName;
  final String mealEmoji;
  final VoidCallback onLeave;

  const _MealImpactLoading({
    required this.mealName,
    required this.mealEmoji,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = mealName?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.proteinLight,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: AppColors.protein, size: 16),
                SizedBox(width: 5),
                Text(
                  'MEAL RECEIVED',
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
          const Spacer(),
          Align(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  alignment: Alignment.center,
                  child: Text(mealEmoji, style: const TextStyle(fontSize: 48)),
                ),
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(11),
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: Text(
              displayName == null || displayName.isEmpty
                  ? 'Logging your meal…'
                  : 'Logging $displayName…',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Updating today’s totals and checking what this means for the rest of your plan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: AppColors.surface,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Usually ready in a few seconds',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onLeave();
            },
            child: const SizedBox(
              width: double.infinity,
              height: 48,
              child: Center(
                child: Text(
                  'Back to today — we’ll keep working',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
}

class _MealLogFailure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _MealLogFailure({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.sync_problem_rounded,
              color: AppColors.error,
              size: 36,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'That didn’t go through.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.9,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textOnPrimary,
                    size: 21,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Try again',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            child: const SizedBox(
              width: double.infinity,
              height: 48,
              child: Center(
                child: Text(
                  'Back to meal logging',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
}

class _MissingImpact extends StatelessWidget {
  final VoidCallback onClose;

  const _MissingImpact({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.textPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nothing to review',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Log a meal first and we’ll show how it fits into your day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Back to today',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
