import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'macro_ring.dart';

class MacroCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double current;
  final double target;
  final Color color;
  final bool isEditable;
  final VoidCallback? onEdit;

  const MacroCard({
    super.key,
    required this.title,
    required this.icon,
    required this.current,
    required this.target,
    required this.color,
    this.isEditable = true,
    this.onEdit,
  });

  double get progress => target > 0 ? current / target : 0.0;
  String get displayValue {
    if (title == 'Calories') {
      return current.toInt().toString();
    }
    return '${current.toInt()}g';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with icon
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ring
          Center(
            child: MacroRing(
              size: 100,
              strokeWidth: 6,
              progress: progress,
              color: color,
              label: displayValue,
              sublabel: title == 'Calories' ? 'Calories left' : null,
              showEditIcon: isEditable,
              onEdit: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}
