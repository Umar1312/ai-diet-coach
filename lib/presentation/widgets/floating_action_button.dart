import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isGlowing;

  const FloatingActionButton({
    super.key,
    required this.onPressed,
    this.isGlowing = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: isGlowing
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: const Icon(Icons.add, color: AppColors.textOnPrimary, size: 32),
      ),
    );
  }
}
