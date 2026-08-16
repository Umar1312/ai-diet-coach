import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/constants/app_colors.dart';
import 'package:diet_coach_ai/main.dart' show notificationStore;

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _toggle(BuildContext context, bool value) async {
    HapticFeedback.selectionClick();
    final allowed = await notificationStore.setEnabled(value);
    if (!context.mounted || !value || allowed) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          backgroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text(
            'Notifications are disabled in iPhone Settings.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
  }

  Future<void> _pickTime(
    BuildContext context,
    String slot,
    int minuteOfDay,
  ) async {
    HapticFeedback.selectionClick();
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
    );
    if (selected == null) return;
    await notificationStore.setTime(slot, selected.hour * 60 + selected.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final enabled = notificationStore.enabled.value;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(onClose: () => context.pop()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                    child: Text(
                      'A gentle check-in at each meal time. Reminders only appear for slots in your daily plan.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                    child: _EnabledCard(
                      enabled: enabled,
                      isUpdating: notificationStore.isUpdating.value,
                      onChanged: (value) => _toggle(context, value),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 12),
                    child: Text(
                      'Meal times',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      for (final entry in notificationStore.times.entries) ...[
                        _TimeCard(
                          slot: entry.key,
                          minuteOfDay: entry.value,
                          enabled: enabled,
                          onTap: () =>
                              _pickTime(context, entry.key, entry.value),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Meal reminders',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnabledCard extends StatelessWidget {
  final bool enabled;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  const _EnabledCard({
    required this.enabled,
    required this.isUpdating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_outlined, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Meal check-ins',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (isUpdating)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.textPrimary,
              ),
            )
          else
            Switch.adaptive(
              value: enabled,
              activeTrackColor: AppColors.success,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String slot;
  final int minuteOfDay;
  final bool enabled;
  final VoidCallback onTap;

  const _TimeCard({
    required this.slot,
    required this.minuteOfDay,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(_emoji(slot), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _label(slot),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                time.format(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(String value) => switch (value) {
    'breakfast' => 'Breakfast',
    'lunch' => 'Lunch',
    'snack' => 'Snack',
    'dinner' => 'Dinner',
    'late' => 'Late meal',
    _ => value,
  };

  String _emoji(String value) => switch (value) {
    'breakfast' => '🌅',
    'lunch' => '🌞',
    'snack' => '🍎',
    'dinner' => '🌙',
    'late' => '🌃',
    _ => '🍽️',
  };
}
