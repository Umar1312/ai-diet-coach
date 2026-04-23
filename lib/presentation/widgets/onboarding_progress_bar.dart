import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int step;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.step,
    this.totalSteps = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < step;
          final isCurrent = index == step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
