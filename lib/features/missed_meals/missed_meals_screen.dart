import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/features/missed_meals/widgets/swipe_card.dart';

/// Full-screen Tinder-style card stack for catching up on missed meals.
/// Asks: "Did you eat this?" — swipe right to confirm, left to skip.
class MissedMealsScreen extends StatefulWidget {
  final List<PlannedMeal> missedMeals;
  final Function(PlannedMeal) onLogMeal;
  final Function(PlannedMeal) onSkipMeal;
  final VoidCallback onDone;

  const MissedMealsScreen({
    super.key,
    required this.missedMeals,
    required this.onLogMeal,
    required this.onSkipMeal,
    required this.onDone,
  });

  @override
  State<MissedMealsScreen> createState() => _MissedMealsScreenState();
}

class _MissedMealsScreenState extends State<MissedMealsScreen>
    with TickerProviderStateMixin {
  late List<PlannedMeal> _stack;
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _stack = List.from(widget.missedMeals);
  }

  void _onSwipeRight() {
    if (_isAnimating || _currentIndex >= _stack.length) return;
    HapticFeedback.heavyImpact();

    final meal = _stack[_currentIndex];
    widget.onLogMeal(meal);

    setState(() {
      _isAnimating = true;
    });

    // Wait for card exit animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _isAnimating = false;
      });
      _checkDone();
    });
  }

  void _onSwipeLeft() {
    if (_isAnimating || _currentIndex >= _stack.length) return;
    HapticFeedback.heavyImpact();

    final meal = _stack[_currentIndex];
    widget.onSkipMeal(meal);

    setState(() {
      _isAnimating = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _isAnimating = false;
      });
      _checkDone();
    });
  }

  void _checkDone() {
    if (_currentIndex >= _stack.length) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) widget.onDone();
      });
    }
  }

  void _onTapLog() {
    if (!_isAnimating && _currentIndex < _stack.length) {
      _onSwipeRight();
    }
  }

  void _onTapSkip() {
    if (!_isAnimating && _currentIndex < _stack.length) {
      _onSwipeLeft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _stack.length - _currentIndex;
    final currentMeal = remaining > 0 ? _stack[_currentIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Soft bokeh background
            const _BokehBackground(),
            Column(
              children: [
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Did you eat as planned?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -1.0,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$remaining meals to check in on',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onDone,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Card stack
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background cards (for depth effect)
                      ..._buildBackgroundCards(),

                      // Active card
                      if (currentMeal != null)
                        SwipeCard(
                          key: ValueKey(currentMeal.order),
                          plannedMeal: currentMeal,
                          isTop: true,
                          onSwipeRight: _onSwipeRight,
                          onSwipeLeft: _onSwipeLeft,
                        ),

                      // Empty state
                      if (remaining == 0)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.success,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'All caught up!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Thanks for checking in',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Skip button
                      _ActionButton(
                        icon: Icons.close_rounded,
                        color: AppColors.error,
                        onTap: _onTapSkip,
                        label: 'I skipped it',
                      ),
                      const SizedBox(width: 40),

                      // Log button
                      _ActionButton(
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        onTap: _onTapLog,
                        label: 'Yes, I ate it',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Hint text
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Swipe right if you ate it  •  Swipe left if you skipped it',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundCards() {
    final widgets = <Widget>[];
    final remaining = _stack.length - _currentIndex;

    // Show up to 2 background cards
    // Add furthest back first (depth 2), then closer (depth 1)
    for (int i = 2; i >= 1; i--) {
      if (remaining - i > 0) {
        final nextMeal = _stack[_currentIndex + i];
        widgets.add(
          SwipeCard(
            key: ValueKey(nextMeal.order),
            plannedMeal: nextMeal,
            isTop: false,
            depth: i,
          ),
        );
      }
    }
    return widgets;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft bokeh background with blurred circles
class _BokehBackground extends StatelessWidget {
  const _BokehBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Top left soft glow
          Positioned(
            top: -80,
            left: -60,
            child: _BokehCircle(
              size: 280,
              color: AppColors.calories.withValues(alpha: 0.06),
            ),
          ),
          // Top right soft glow
          Positioned(
            top: -40,
            right: -80,
            child: _BokehCircle(
              size: 320,
              color: AppColors.protein.withValues(alpha: 0.05),
            ),
          ),
          // Bottom left
          Positioned(
            bottom: 100,
            left: -100,
            child: _BokehCircle(
              size: 240,
              color: AppColors.carbs.withValues(alpha: 0.04),
            ),
          ),
          // Bottom right
          Positioned(
            bottom: 60,
            right: -60,
            child: _BokehCircle(
              size: 260,
              color: AppColors.fats.withValues(alpha: 0.05),
            ),
          ),
          // Center subtle
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.2,
            child: _BokehCircle(
              size: 200,
              color: AppColors.primary.withValues(alpha: 0.02),
            ),
          ),
        ],
      ),
    );
  }
}

class _BokehCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BokehCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
