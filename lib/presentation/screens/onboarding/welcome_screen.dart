import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          children: [
            const _PlanHero(),
            const SizedBox(height: 28),
            Text(
              'Stop wondering\nwhat to eat next',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${AppConstants.appName} builds a daily meal plan around your goals and adapts as you log.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            const _BenefitsPanel(),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                SizedBox(width: 6),
                Text(
                  'Takes about 2 minutes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              height: 64,
              text: 'Build my plan',
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/login');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PlanHero extends StatelessWidget {
  const _PlanHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      decoration: BoxDecoration(
        color: AppColors.proteinLight,
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              left: -32,
              top: -40,
              child: _DecorativeCircle(
                size: 120,
                color: AppColors.carbs.withValues(alpha: 0.15),
              ),
            ),
            Positioned(
              right: -28,
              bottom: -52,
              child: _DecorativeCircle(
                size: 140,
                color: AppColors.fats.withValues(alpha: 0.13),
              ),
            ),
            const Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Center(child: _HeroLabel()),
            ),
            const Positioned(
              left: 24,
              bottom: 24,
              child: _MealTile(emoji: '🥣', label: 'Breakfast'),
            ),
            const Positioned(
              right: 24,
              bottom: 24,
              child: _MealTile(emoji: '🥗', label: 'Dinner'),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 21,
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 5),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.textOnPrimary,
                    size: 28,
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

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeroLabel extends StatelessWidget {
  const _HeroLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 14),
          SizedBox(width: 7),
          Text(
            'YOUR DAY, PLANNED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  final String emoji;
  final String label;

  const _MealTile({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 25)),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsPanel extends StatelessWidget {
  const _BenefitsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _BenefitRow(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: AppColors.carbs,
            iconBackground: AppColors.carbsLight,
            title: 'No more meal guesswork',
            detail: 'See exactly what to eat next for your goals.',
          ),
          Divider(height: 1, color: AppColors.border),
          _BenefitRow(
            icon: Icons.sync_rounded,
            iconColor: AppColors.protein,
            iconBackground: AppColors.proteinLight,
            title: 'Your plan stays realistic',
            detail: 'It adapts as you log meals—not tomorrow.',
          ),
          Divider(height: 1, color: AppColors.border),
          _BenefitRow(
            icon: Icons.favorite_outline_rounded,
            iconColor: AppColors.calories,
            iconBackground: AppColors.caloriesLight,
            title: 'Food that fits your life',
            detail: 'Built around your tastes, restrictions, and pantry.',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String detail;

  const _BenefitRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.35,
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
