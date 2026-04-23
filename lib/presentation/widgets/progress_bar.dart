import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final bool showGradient;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: showGradient
                ? const LinearGradient(colors: AppColors.progressGradient)
                : null,
            color: showGradient ? null : AppColors.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
