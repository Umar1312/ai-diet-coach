import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/features/subscription/subscription_gate.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore, subscriptionStore;
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

/// CalAI-style dashboard: massive text, extreme minimalism, only what matters.
class DashboardScreen extends StatefulWidget {
  final bool Function()? hasProAccess;

  const DashboardScreen({super.key, this.hasProAccess});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboard());
  }

  Future<void> _loadDashboard() async {
    if (!dashboardStore.hasLoaded.value && !dashboardStore.isLoading.value) {
      await dashboardStore.refresh();
    }
    await _ensureDayPlan();
  }

  Future<void> _refreshDashboard() async {
    await dashboardStore.refresh();
    await _ensureDayPlan();
  }

  Future<void> _ensureDayPlan() async {
    if (!mounted || !dashboardStore.hasLoaded.value) return;
    final hasProAccess =
        widget.hasProAccess?.call() ?? subscriptionStore.hasAccess.value;
    if (!hasProAccess) return;
    if (dashboardStore.plannedMeals.isEmpty &&
        dashboardStore.todayMeals.isEmpty &&
        !dashboardStore.isGeneratingPlan.value) {
      await dashboardStore.fetchDayPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await _refreshDashboard();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: _Greeting()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              const SliverToBoxAdapter(child: _CalorieHero()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              const SliverToBoxAdapter(child: _TodayPlan()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              const SliverToBoxAdapter(child: _BigLogButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              // Trailing scroll room for the floating glass navigation bar.
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Greeting
// ═══════════════════════════════════════════════════════════════════════════

class _Greeting extends StatelessWidget {
  const _Greeting();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _today() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _today(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Calorie Hero — one massive number
// ═══════════════════════════════════════════════════════════════════════════

class _CalorieHero extends StatelessWidget {
  const _CalorieHero();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = dashboardStore;
        if (!store.hasLoaded.value && store.isLoading.value) {
          return const _CalorieLoadingCard();
        }
        if (!store.hasLoaded.value && store.hasError.value) {
          return _DashboardErrorCard(message: store.errorMessage.value);
        }

        final calLeft = store.caloriesLeft.value.clamp(-9999, 9999);

        final rings = [
          _RingData(
            radius: 82,
            strokeWidth: 10,
            progress: store.caloriesProgress.value.clamp(0.0, 1.0),
            color: AppColors.calories,
          ),
          _RingData(
            radius: 68,
            strokeWidth: 9,
            progress: store.proteinProgress.value.clamp(0.0, 1.0),
            color: AppColors.protein,
          ),
          _RingData(
            radius: 54,
            strokeWidth: 9,
            progress: store.carbsProgress.value.clamp(0.0, 1.0),
            color: AppColors.carbs,
          ),
          _RingData(
            radius: 40,
            strokeWidth: 7,
            progress: store.fatsProgress.value.clamp(0.0, 1.0),
            color: AppColors.fats,
          ),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(
                width: 184,
                height: 184,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(184, 184),
                      painter: _MacroRingsPainter(rings: rings),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$calLeft',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'cal left',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MacroLegendDot(
                    color: AppColors.protein,
                    label: '${store.proteinLeft.value.clamp(0, 999)}g P',
                  ),
                  const SizedBox(width: 20),
                  _MacroLegendDot(
                    color: AppColors.carbs,
                    label:
                        '${(store.targetCarbs.value - store.consumedCarbs.value).clamp(0, 999)}g C',
                  ),
                  const SizedBox(width: 20),
                  _MacroLegendDot(
                    color: AppColors.fats,
                    label:
                        '${(store.targetFats.value - store.consumedFats.value).clamp(0, 999)}g F',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingData {
  final double radius;
  final double strokeWidth;
  final double progress;
  final Color color;

  _RingData({
    required this.radius,
    required this.strokeWidth,
    required this.progress,
    required this.color,
  });
}

class _MacroRingsPainter extends CustomPainter {
  final List<_RingData> rings;

  _MacroRingsPainter({required this.rings});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final ring in rings) {
      // Background track
      final trackPaint = Paint()
        ..color = ring.color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, ring.radius, trackPaint);

      // Progress arc
      final progressPaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * ring.progress.clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: center, radius: ring.radius);

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingsPainter old) => true;
}

class _MacroLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _MacroLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Today's plan — compact overview
// ═══════════════════════════════════════════════════════════════════════════

class _TodayPlan extends StatelessWidget {
  const _TodayPlan();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = dashboardStore;
        if (!store.hasLoaded.value) {
          return const SizedBox.shrink();
        }
        final meals = store.plannedMeals.toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        final remainingMeals = meals
            .where((meal) => meal.status == PlannedMealStatus.planned)
            .toList();
        final nextOrder = remainingMeals.isEmpty
            ? null
            : remainingMeals.first.order;
        final completed = meals
            .where((meal) => meal.status == PlannedMealStatus.logged)
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
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
                ],
              ),
              const SizedBox(height: 14),
              if (meals.isEmpty)
                _PlanUnavailable(isLoading: store.isGeneratingPlan.value)
              else
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.go('/plan');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.textPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                completed == meals.length
                                    ? 'Day complete'
                                    : '$completed of ${meals.length} meals logged',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (var index = 0; index < meals.length; index++) ...[
                          _TodayPlanRow(
                            plannedMeal: meals[index],
                            isNext: meals[index].order == nextOrder,
                          ),
                          if (index != meals.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.border,
                              indent: 56,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayPlanRow extends StatelessWidget {
  final PlannedMeal plannedMeal;
  final bool isNext;

  const _TodayPlanRow({required this.plannedMeal, required this.isNext});

  String get _slotLabel => switch (plannedMeal.slot) {
    'breakfast' => 'BREAKFAST',
    'lunch' => 'LUNCH',
    'snack' => 'SNACK',
    'dinner' => 'DINNER',
    'late' => 'LATE MEAL',
    _ => plannedMeal.slot.toUpperCase(),
  };

  @override
  Widget build(BuildContext context) {
    final meal = plannedMeal.meal;
    final isLogged = plannedMeal.status == PlannedMealStatus.logged;
    final isSkipped = plannedMeal.status == PlannedMealStatus.skipped;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isSkipped ? 0.48 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(meal.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _slotLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (isNext) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.proteinLight,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'NEXT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.protein,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isLogged
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isSkipped ? TextDecoration.lineThrough : null,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${meal.calories} cal  ·  ${meal.proteinG}g protein',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isLogged)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.proteinLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.protein,
                  size: 17,
                ),
              )
            else if (isSkipped)
              const Icon(
                Icons.remove_rounded,
                color: AppColors.textTertiary,
                size: 22,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanUnavailable extends StatelessWidget {
  final bool isLoading;

  const _PlanUnavailable({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textPrimary,
                ),
                strokeWidth: 2.5,
              ),
            )
          else
            const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isLoading
                  ? 'Building today’s plan…'
                  : 'Today’s plan couldn’t load.',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (!isLoading)
            GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                if (!await requireProAccess(context)) return;
                await dashboardStore.fetchDayPlan();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalorieLoadingCard extends StatelessWidget {
  const _CalorieLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  final String message;

  const _DashboardErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.isEmpty ? 'Pull to retry or try again now.' : message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                dashboardStore.refresh();
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Big Log Button
// ═══════════════════════════════════════════════════════════════════════════

class _BigLogButton extends StatelessWidget {
  const _BigLogButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('/log');
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
              Icon(Icons.add_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Log a meal',
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
    );
  }
}
