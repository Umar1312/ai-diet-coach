import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/features/missed_meals/missed_meals_screen.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

/// Shell for the main app tabs. Wraps Home / Pantry / Plan / Profile
/// with a persistent bottom nav. Child comes from go_router's
/// StatefulShellRoute branch.
class HomeShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _tabs = <_TabItem>[
    _TabItem(label: 'Home', icon: Icons.home_rounded),
    _TabItem(label: 'Pantry', icon: Icons.kitchen_rounded),
    _TabItem(label: 'Plan', icon: Icons.calendar_today_rounded),
    _TabItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  ReactionDisposer? _missedMealsReaction;
  bool _hasShownMissedMealsToday = false;

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    // Show missed meals when dashboard finishes loading
    _missedMealsReaction = reaction((_) => dashboardStore.isLoading.value, (
      isLoading,
    ) {
      if (!isLoading && mounted && !_hasShownMissedMealsToday) {
        _checkAndShowMissedMeals();
      }
    });
  }

  @override
  void dispose() {
    _missedMealsReaction?.call();
    super.dispose();
  }

  void _checkAndShowMissedMeals() {
    final missed = _getMissedMeals();
    if (missed.isNotEmpty) {
      _hasShownMissedMealsToday = true;
      _showMissedMealsScreen(missed);
    }
  }

  List<PlannedMeal> _getMissedMeals() {
    final hour = DateTime.now().hour;
    const slotEndTimes = {
      'breakfast': 11,
      'lunch': 15,
      'snack': 17,
      'dinner': 21,
      'late': 23,
    };

    return dashboardStore.plannedMeals.where((meal) {
      if (meal.status != PlannedMealStatus.planned) return false;
      if (meal.isOptional) return false;
      final endHour = slotEndTimes[meal.slot.toLowerCase()];
      if (endHour == null) return false;
      return hour > endHour;
    }).toList();
  }

  void _showMissedMealsScreen(List<PlannedMeal> missed) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => MissedMealsScreen(
          missedMeals: missed,
          onLogMeal: (meal) async {
            await dashboardStore.addMeal(
              meal.meal,
              source: 'recommendation',
              slot: meal.slot,
            );
          },
          onSkipMeal: (meal) async {
            await dashboardStore.skipSlot(meal.order);
          },
          onDone: () {
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
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
