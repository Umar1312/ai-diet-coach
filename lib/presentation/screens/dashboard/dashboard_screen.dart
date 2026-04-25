import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;

/// CalAI-style dashboard: massive text, extreme minimalism, only what matters.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            await dashboardStore.refresh();
          },
          child: Observer(
            builder: (_) {
              final store = dashboardStore;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: _Greeting()),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  SliverToBoxAdapter(child: _CalorieHero(store: store)),
                  const SliverToBoxAdapter(child: SizedBox(height: 56)),
                  SliverToBoxAdapter(child: _NextMeal(store: store)),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  const SliverToBoxAdapter(child: _BigLogButton()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
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
  final DashboardStore store;
  const _CalorieHero({required this.store});

  @override
  Widget build(BuildContext context) {
    final calLeft = store.caloriesLeft.value.clamp(-9999, 9999);

    final rings = [
      _RingData(
        radius: 142,
        strokeWidth: 14,
        progress: store.caloriesProgress.value.clamp(0.0, 1.0),
        color: AppColors.calories,
      ),
      _RingData(
        radius: 117,
        strokeWidth: 13,
        progress: store.proteinProgress.value.clamp(0.0, 1.0),
        color: AppColors.protein,
      ),
      _RingData(
        radius: 92,
        strokeWidth: 13,
        progress: store.carbsProgress.value.clamp(0.0, 1.0),
        color: AppColors.carbs,
      ),
      _RingData(
        radius: 67,
        strokeWidth: 11,
        progress: store.fatsProgress.value.clamp(0.0, 1.0),
        color: AppColors.fats,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SizedBox(
            width: 306,
            height: 306,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(306, 306),
                  painter: _MacroRingsPainter(rings: rings),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$calLeft',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'cal left',
                      style: TextStyle(
                        fontSize: 14,
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
          const SizedBox(height: 28),
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
// Next Meal — one big recommendation
// ═══════════════════════════════════════════════════════════════════════════

class _NextMeal extends StatelessWidget {
  final DashboardStore store;
  const _NextMeal({required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final meal = store.nextMeal.value;
        if (meal == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Up next',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            meal.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.8,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(meal.emoji, style: const TextStyle(fontSize: 40)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      meal.whyItFits,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          store.acceptNextMeal();
                          _showAcceptedSnack(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        child: const Text("I'll eat this"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          store.swapNextMeal();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Suggest something else'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAcceptedSnack(BuildContext context) {
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
          _showLogOptions(context);
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

  void _showLogOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
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
            const Text(
              'Log a meal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How do you want to log?',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            _LogOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a photo',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                context.push('/camera');
              },
            ),
            const SizedBox(height: 12),
            _LogOption(
              icon: Icons.edit_note_rounded,
              label: 'Type it in',
              color: AppColors.textPrimary,
              onTap: () {
                Navigator.pop(context);
                context.push('/log/text');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LogOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LogOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
