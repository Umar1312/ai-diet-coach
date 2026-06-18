import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

/// Tinder-style swipe card with spring physics, rotation, and overlay indicators.
class SwipeCard extends StatefulWidget {
  final PlannedMeal plannedMeal;
  final bool isTop;
  final int depth; // 0 = top, 1 = just behind, 2 = furthest back
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final double? topCardPosition;
  final double? topCardAngle;

  const SwipeCard({
    super.key,
    required this.plannedMeal,
    required this.isTop,
    this.depth = 0,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.topCardPosition,
    this.topCardAngle,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  static const _swipeThreshold = 80.0;
  static const _swipeVelocity = 400.0;

  double _dragPosition = 0.0;
  double _angle = 0.0;
  bool _isExiting = false;

  @override
  void didUpdateWidget(covariant SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent-driven position for the top card
    if (widget.isTop && widget.topCardPosition != null) {
      _dragPosition = widget.topCardPosition!;
      _angle = widget.topCardAngle ?? 0.0;
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.isTop || _isExiting) return;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.isTop || _isExiting) return;
    setState(() {
      _dragPosition += details.delta.dx;
      _angle = (_dragPosition / 200) * (pi / 12);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.isTop || _isExiting) return;
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (_dragPosition > _swipeThreshold || velocity > _swipeVelocity) {
      _swipeRight();
    } else if (_dragPosition < -_swipeThreshold || velocity < -_swipeVelocity) {
      _swipeLeft();
    } else {
      _resetPosition();
    }
  }

  void _swipeRight() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExiting = true;
      _dragPosition = MediaQuery.of(context).size.width + 200;
      _angle = pi / 8;
    });
    widget.onSwipeRight?.call();
  }

  void _swipeLeft() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExiting = true;
      _dragPosition = -(MediaQuery.of(context).size.width + 200);
      _angle = -pi / 8;
    });
    widget.onSwipeLeft?.call();
  }

  void _resetPosition() {
    setState(() {
      _dragPosition = 0.0;
      _angle = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 28.0;
    final cardWidth = screenWidth - (horizontalPadding * 2);

    // For non-top cards, scale down, shift back, and peek out
    // Each card behind is smaller and more offset so you can see them
    final depth = widget.isTop ? 0 : widget.depth;
    final scale = widget.isTop ? 1.0 : 0.90 - (depth * 0.04);
    final yOffset = widget.isTop ? 0.0 : 20.0 + (depth * 14);
    final horizontalOffset = widget.isTop ? 0.0 : (depth.isOdd ? 12.0 : -12.0);

    // Calculate overlay opacity based on drag
    final likeOpacity = _dragPosition / _swipeThreshold;
    final nopeOpacity = -_dragPosition / _swipeThreshold;

    return Positioned(
      left: horizontalPadding + _dragPosition + horizontalOffset,
      top: yOffset,
      child: Transform.rotate(
        angle: _angle,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: GestureDetector(
            onPanStart: _onDragStart,
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd,
            child: SizedBox(
              width: cardWidth,
              height: cardWidth * 1.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // Card background
                    Container(
                      width: cardWidth,
                      height: cardWidth * 1.35,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(32),
                        border: widget.isTop
                            ? null
                            : Border.all(color: AppColors.border, width: 0.5),
                        boxShadow: widget.isTop
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                    ),

                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Slot label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _capitalize(widget.plannedMeal.slot),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Emoji
                          Text(
                            widget.plannedMeal.meal.emoji,
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 20),

                          // Meal name
                          Text(
                            widget.plannedMeal.meal.name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Question
                          Text(
                            'Did you eat this?',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Macros
                          Row(
                            children: [
                              _MacroPill(
                                label:
                                    '${widget.plannedMeal.meal.calories} cal',
                                color: AppColors.calories,
                              ),
                              const SizedBox(width: 8),
                              _MacroPill(
                                label: '${widget.plannedMeal.meal.proteinG}g P',
                                color: AppColors.protein,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _MacroPill(
                                label: '${widget.plannedMeal.meal.carbsG}g C',
                                color: AppColors.carbs,
                              ),
                              const SizedBox(width: 8),
                              _MacroPill(
                                label: '${widget.plannedMeal.meal.fatsG}g F',
                                color: AppColors.fats,
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Prep time
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.plannedMeal.meal.prepMinutes} min',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Like overlay (swipe right)
                    Positioned(
                      top: 40,
                      left: 20,
                      child: Opacity(
                        opacity: likeOpacity.clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.success,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'I ATE THIS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Nope overlay (swipe left)
                    Positioned(
                      top: 40,
                      right: 20,
                      child: Opacity(
                        opacity: nopeOpacity.clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.error,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SKIPPED IT',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
