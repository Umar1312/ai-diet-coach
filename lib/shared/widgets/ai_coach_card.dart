import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/dashboard_state.dart';

class AICoachCard extends StatelessWidget {
  final AICardState cardState;
  final String message;
  final VoidCallback? onTap;

  const AICoachCard({
    super.key,
    required this.cardState,
    required this.message,
    this.onTap,
  });

  Color get _accentColor {
    switch (cardState) {
      case AICardState.onTrack:
        return AppColors.success;
      case AICardState.skippedMeal:
        return AppColors.warning;
      case AICardState.behindProtein:
        return AppColors.protein;
      case AICardState.calorieLimit:
        return AppColors.carbs;
      case AICardState.goalHit:
        return AppColors.aiGlow;
    }
  }

  IconData get _icon {
    switch (cardState) {
      case AICardState.onTrack:
        return Icons.check_circle_rounded;
      case AICardState.skippedMeal:
        return Icons.schedule_rounded;
      case AICardState.behindProtein:
        return Icons.fitness_center_rounded;
      case AICardState.calorieLimit:
        return Icons.local_fire_department_rounded;
      case AICardState.goalHit:
        return Icons.emoji_events_rounded;
    }
  }

  String get _title {
    switch (cardState) {
      case AICardState.onTrack:
        return 'On Track';
      case AICardState.skippedMeal:
        return 'Skipped Meal';
      case AICardState.behindProtein:
        return 'Behind on Protein';
      case AICardState.calorieLimit:
        return 'Calorie Limit';
      case AICardState.goalHit:
        return 'Goal Hit!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accentColor.withValues(alpha: 0.08),
              _accentColor.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _accentColor.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accentColor.withValues(alpha: 0.2),
                      _accentColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: _accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: _accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Coach',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _accentColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
