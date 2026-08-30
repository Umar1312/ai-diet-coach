import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';

/// Shell for the main app tabs. Wraps Home / Pantry / Plan
/// with a persistent bottom nav. Child comes from go_router's
/// StatefulShellRoute branch.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  static const _navHeight = 64.0;
  static const _navBottomMargin = 12.0;

  static const _tabs = <_TabItem>[
    _TabItem(label: 'Home', icon: Icons.home_rounded),
    _TabItem(label: 'Pantry', icon: Icons.kitchen_rounded),
    _TabItem(label: 'Plan', icon: Icons.calendar_today_rounded),
  ];

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + _navHeight + _navBottomMargin;

    return LiquidGlassScaffold(
      backgroundColor: AppColors.background,
      // LiquidGlassScaffold intentionally overlays floating chrome on its
      // body. Reserve the same space a normal Scaffold bottom nav would, so
      // the last item in every tab remains above the glass bar.
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: navigationShell,
      ),
      bottomNavigationBar: LiquidGlassTabBar(
        width: MediaQuery.sizeOf(context).width - 32,
        height: _navHeight,
        margin: const EdgeInsets.only(bottom: _navBottomMargin),
        selectedIndex: navigationShell.currentIndex,
        items: _tabs
            .map(
              (tab) => LiquidGlassTabBarItem(label: tab.label, icon: tab.icon),
            )
            .toList(),
        onChanged: _onTap,
        itemPadding: 4,
        itemStyle: const LiquidGlassTabItemStyle(
          selectedColor: AppColors.textPrimary,
          unselectedColor: AppColors.textTertiary,
          iconSize: 22,
          labelFontSize: 11,
          iconLabelGap: 4,
          selectedFontWeight: FontWeight.w600,
          unselectedFontWeight: FontWeight.w500,
        ),
        pillStyle: const LiquidGlassTabPillStyle(
          animated: true,
          color: Color(0x1F1E1A24),
        ),
        style: LiquidGlassTabBar.defaultStyle.copyWith(
          appearance: const LiquidGlassAppearance(
            color: Color(0xD9FFFFFF),
            blur: LiquidGlassBlur(sigmaX: 8, sigmaY: 8),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}
