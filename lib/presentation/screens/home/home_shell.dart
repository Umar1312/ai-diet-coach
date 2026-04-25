import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';

/// Shell for the main app tabs. Wraps Home / Pantry / Plan / Profile
/// with a persistent bottom nav. Child comes from go_router's
/// StatefulShellRoute branch.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  static const _tabs = <_TabItem>[
    _TabItem(label: 'Home', icon: Icons.home_rounded),
    _TabItem(label: 'Pantry', icon: Icons.kitchen_rounded),
    _TabItem(label: 'Plan', icon: Icons.calendar_today_rounded),
    _TabItem(label: 'Profile', icon: Icons.person_rounded),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        tabs: _tabs,
        onTap: _onTap,
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: _NavItem(tab: tabs[i], active: active),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool active;

  const _NavItem({required this.tab, required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tab.icon,
            size: 22,
            color: active ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(height: 4),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.textTertiary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
