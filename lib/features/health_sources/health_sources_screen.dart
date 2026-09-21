import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/legal/legal_links.dart';

/// Opens the hosted sources page in the system's in-app browser.
class HealthSourcesLink extends StatelessWidget {
  const HealthSourcesLink({super.key});

  static Future<void> open(BuildContext context) async {
    HapticFeedback.selectionClick();
    await LegalLinks.openHealthSources();
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => open(context),
    icon: const Icon(Icons.menu_book_outlined, size: 20),
    label: const Text('Health sources & calculations'),
    style: TextButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      minimumSize: const Size(48, 48),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}
