import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_coach_ai/core/constants/app_colors.dart';

import 'package:diet_coach_ai/shared/widgets/macro_ring.dart';
import 'package:diet_coach_ai/shared/widgets/ai_coach_card.dart';
import 'package:diet_coach_ai/shared/widgets/shimmer_widgets.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';
import 'package:shimmer/shimmer.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    dashboardStore.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await dashboardStore.fetchDashboard();
          },
          child: Observer(
            builder: (_) {
              final store = dashboardStore;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(
                    child: store.isLoading
                        ? _buildShimmerContent()
                        : _buildCalorieSection(context, store),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: store.isLoading
                        ? const ShimmerCard(height: 90)
                        : AICoachCard(
                            cardState: store.aiCardState,
                            message: store.aiCardText,
                            onTap: () {},
                          ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader("Today's Meals"),
                  ),
                  store.isLoading
                      ? SliverToBoxAdapter(
                          child: Column(
                            children: List.generate(
                              3,
                              (_) => const ShimmerMealItem(),
                            ),
                          ),
                        )
                      : store.todayMeals.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyMeals())
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildMealSlot(
                                context,
                                store.todayMeals[index],
                                index,
                              ),
                              childCount: store.todayMeals.length,
                            ),
                          ),
                        ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Observer(
        builder: (_) {
          if (dashboardStore.isLoading) return const SizedBox.shrink();
          return _buildLogButton(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          // Profile avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calorie + Macro Section ─────────────────────────────────────────────

  Widget _buildCalorieSection(BuildContext context, DashboardStore store) {
    final remaining = store.targetCalories - store.consumedCalories;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main calorie ring ──
          MacroRing(
            size: 200,
            strokeWidth: 16,
            progress: store.caloriesProgress.clamp(0.0, 1.0),
            color: AppColors.calories,
            gradientEnd: const Color(0xFF6DD5A0),
            label: '$remaining',
            sublabel: 'kcal left',
          ),
          const SizedBox(height: 12),

          // Consumed / Target pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.caloriesLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.caloriesDeep,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${store.consumedCalories} of ${store.targetCalories} kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.caloriesDeep,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Divider ──
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.border.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Mini macro rings row ──
          Row(
            children: [
              _MacroMiniCard(
                label: 'Protein',
                consumed: store.consumedProtein,
                target: store.targetProtein,
                progress: store.proteinProgress.clamp(0.0, 1.0),
                color: AppColors.protein,
                bgColor: AppColors.proteinLight,
                icon: Icons.egg_outlined,
              ),
              const SizedBox(width: 10),
              _MacroMiniCard(
                label: 'Carbs',
                consumed: store.consumedCarbs,
                target: store.targetCarbs,
                progress: store.carbsProgress.clamp(0.0, 1.0),
                color: AppColors.carbs,
                bgColor: AppColors.carbsLight,
                icon: Icons.grain_rounded,
              ),
              const SizedBox(width: 10),
              _MacroMiniCard(
                label: 'Fats',
                consumed: store.consumedFats,
                target: store.targetFats,
                progress: store.fatsProgress.clamp(0.0, 1.0),
                color: AppColors.fats,
                bgColor: AppColors.fatsLight,
                icon: Icons.water_drop_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shimmer loading ─────────────────────────────────────────────────────

  Widget _buildShimmerContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const ShimmerRing(size: 200),
          const SizedBox(height: 24),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Shimmer.fromColors(
                baseColor: AppColors.surface2,
                highlightColor: const Color(0xFFE8E8ED),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/history'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty meal slots ────────────────────────────────────────────────────

  Widget _buildEmptyMeals() {
    final slots = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    return Column(
      children: slots.map((slot) => _buildEmptySlot(slot)).toList(),
    );
  }

  Widget _buildEmptySlot(String mealName) {
    final config = {
      'Breakfast': (
        Icons.wb_sunny_rounded,
        AppColors.carbs,
        AppColors.carbsLight,
        '7 - 9 AM',
      ),
      'Lunch': (
        Icons.lunch_dining_rounded,
        AppColors.calories,
        AppColors.caloriesLight,
        '12 - 2 PM',
      ),
      'Dinner': (
        Icons.dinner_dining_rounded,
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.08),
        '6 - 8 PM',
      ),
      'Snack': (
        Icons.cookie_rounded,
        AppColors.fats,
        AppColors.fatsLight,
        'Anytime',
      ),
    };
    final (icon, color, bgColor, timeHint) =
        config[mealName] ??
        (Icons.restaurant, AppColors.textTertiary, AppColors.surface2, '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            // Left accent bar
            Container(width: 4, height: 68, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeHint,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showLogOptions(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+ Add',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logged meal row ─────────────────────────────────────────────────────

  Widget _buildMealSlot(BuildContext context, dynamic meal, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(width: 4, height: 72, color: AppColors.calories),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.caloriesLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.caloriesDeep,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.foodName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _MealMacroChip(
                                value: '${meal.calories}',
                                unit: 'cal',
                                color: AppColors.caloriesDeep,
                                bgColor: AppColors.caloriesLight,
                              ),
                              const SizedBox(width: 6),
                              _MealMacroChip(
                                value: '${meal.protein}g',
                                unit: 'pro',
                                color: AppColors.protein,
                                bgColor: AppColors.proteinLight,
                              ),
                              const SizedBox(width: 6),
                              _MealMacroChip(
                                value: '${meal.carbs}g',
                                unit: 'carb',
                                color: AppColors.carbs,
                                bgColor: AppColors.carbsLight,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(meal.loggedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ─────────────────────────────────────────────────────────────────

  Widget _buildLogButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogOptions(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B7CF6), Color(0xFF6C5CE7)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  // ── Bottom sheet ────────────────────────────────────────────────────────

  void _showLogOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Log a meal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose how you want to log your food',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            _LogOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a photo',
              subtitle: 'Snap your plate for instant analysis',
              color: AppColors.calories,
              bgColor: AppColors.caloriesLight,
              onTap: () {
                Navigator.pop(context);
                context.push('/camera');
              },
            ),
            const SizedBox(height: 10),
            _LogOption(
              icon: Icons.mic_rounded,
              label: 'Describe by voice',
              subtitle: 'Tell us what you ate',
              color: AppColors.protein,
              bgColor: AppColors.proteinLight,
              onTap: () {
                Navigator.pop(context);
                context.push('/log/text');
              },
            ),
            const SizedBox(height: 10),
            _LogOption(
              icon: Icons.edit_note_rounded,
              label: 'Type it in',
              subtitle: 'Search or type your meal',
              color: AppColors.carbs,
              bgColor: AppColors.carbsLight,
              onTap: () {
                Navigator.pop(context);
                context.push('/log/text');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Private widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Compact macro card with mini circular progress and value
class _MacroMiniCard extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final double progress;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _MacroMiniCard({
    required this.label,
    required this.consumed,
    required this.target,
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Mini progress ring
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Icon(icon, color: color, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${consumed}g',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '/ ${target}g',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small inline chip for meal macros
class _MealMacroChip extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  final Color bgColor;

  const _MealMacroChip({
    required this.value,
    required this.unit,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value $unit',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Log option row in the bottom sheet
class _LogOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _LogOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
