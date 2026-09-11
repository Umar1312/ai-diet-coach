import 'package:flutter/material.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/core/legal/legal_links.dart';

class LegalFooter extends StatelessWidget {
  const LegalFooter({
    super.key,
    this.prefix = 'By continuing, you agree to our ',
  });

  final String prefix;

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      height: 1.5,
    );
    const bodyStyle = TextStyle(
      fontSize: 13,
      color: AppColors.textTertiary,
      height: 1.5,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: bodyStyle),
        GestureDetector(
          onTap: LegalLinks.openTermsOfUse,
          child: const Text('Terms of Use', style: linkStyle),
        ),
        const Text(' and ', style: bodyStyle),
        GestureDetector(
          onTap: LegalLinks.openPrivacyPolicy,
          child: const Text('Privacy Policy', style: linkStyle),
        ),
        const Text('.', style: bodyStyle),
      ],
    );
  }
}
