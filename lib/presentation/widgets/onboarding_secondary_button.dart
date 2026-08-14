import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';

class OnboardingSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const OnboardingSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: onPressed == null
                  ? AppColors.textTertiary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
