import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// A slider for broad changes, with precise, accessible single-step controls.
class StepperSlider extends StatelessWidget {
  const StepperSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.step = 1,
    this.semanticLabel = 'Value',
  });

  final double value, min, max, step;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final current = value.clamp(min, max);
    Widget button(bool increase) {
      final enabled =
          onChanged != null && (increase ? current < max : current > min);
      return IconButton(
        tooltip: '${increase ? 'Increase' : 'Decrease'} $semanticLabel',
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textTertiary,
        ),
        onPressed: !enabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                final next = (current + (increase ? step : -step));
                onChanged!(
                  (double.parse(next.toStringAsFixed(6))).clamp(min, max),
                );
              },
        icon: Icon(
          increase ? Icons.add_rounded : Icons.remove_rounded,
          size: 22,
        ),
      );
    }

    final slider = Semantics(
      label: semanticLabel,
      child: Slider(
        value: current,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 240) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              slider,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [button(false), button(true)],
              ),
            ],
          );
        }
        return Row(
          children: [
            button(false),
            Expanded(child: slider),
            button(true),
          ],
        );
      },
    );
  }
}
