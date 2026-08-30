import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diet_coach_ai/core/services/meal_notification_service.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

class NotificationStore {
  static const defaultTimes = <String, int>{
    'breakfast': 8 * 60 + 30,
    'lunch': 13 * 60,
    'snack': 16 * 60 + 30,
    'dinner': 20 * 60,
    'late': 22 * 60,
  };
  static const _enabledKey = 'meal_notifications_enabled';
  static const _timeKeyPrefix = 'meal_notification_time_';

  final MealNotificationService service;
  final SharedPreferencesAsync _preferences;

  NotificationStore({
    required this.service,
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final enabled = Observable<bool>(false);
  final isInitialized = Observable<bool>(false);
  final isUpdating = Observable<bool>(false);
  final times = ObservableMap<String, int>.of(defaultTimes);
  final pendingSlot = Observable<String?>(null);
  Future<void> _syncQueue = Future<void>.value();

  VoidCallback? onOpenCheckIn;

  Future<void> initialize() async {
    await service.initialize();
    service.onTap = _receiveTap;

    final hasSavedPreference = await _preferences.containsKey(_enabledKey);
    final savedEnabled = await _preferences.getBool(_enabledKey);
    var resolvedEnabled = savedEnabled ?? false;
    if (!hasSavedPreference && service.isSupported) {
      resolvedEnabled = await Permission.notification.isGranted;
      await _preferences.setBool(_enabledKey, resolvedEnabled);
    }

    final loadedTimes = <String, int>{};
    for (final entry in defaultTimes.entries) {
      loadedTimes[entry.key] =
          await _preferences.getInt('$_timeKeyPrefix${entry.key}') ??
          entry.value;
    }

    runInAction(() {
      enabled.value = resolvedEnabled;
      times
        ..clear()
        ..addAll(loadedTimes);
      pendingSlot.value = service.initialSlot;
      isInitialized.value = true;
    });
  }

  Future<bool> setEnabled(bool value) async {
    if (!service.isSupported) return false;
    runInAction(() => isUpdating.value = true);
    try {
      var allowed = value;
      if (value) allowed = await service.requestPermission();
      await _preferences.setBool(_enabledKey, allowed);
      runInAction(() => enabled.value = allowed);
      if (!allowed) await service.cancelMealReminders();
      return allowed;
    } finally {
      runInAction(() => isUpdating.value = false);
    }
  }

  Future<void> setTime(String slot, int minuteOfDay) async {
    if (!defaultTimes.containsKey(slot)) return;
    final normalized = minuteOfDay.clamp(0, 1439);
    await _preferences.setInt('$_timeKeyPrefix$slot', normalized);
    runInAction(() => times[slot] = normalized);
  }

  Future<void> syncWithPlan(List<PlannedMeal> plannedMeals) {
    final enabledSnapshot = enabled.value;
    final timesSnapshot = Map<String, int>.from(times);
    final mealsSnapshot = List<PlannedMeal>.from(plannedMeals);
    _syncQueue = _syncQueue.then(
      (_) => service.syncDailyReminders(
        enabled: enabledSnapshot,
        times: timesSnapshot,
        plannedMeals: mealsSnapshot,
      ),
    );
    return _syncQueue;
  }

  Future<void> snooze(String slot) => service.snooze(slot);

  String? takePendingSlot() {
    final slot = pendingSlot.value;
    runInAction(() => pendingSlot.value = null);
    return slot;
  }

  void _receiveTap(String slot) {
    runInAction(() => pendingSlot.value = slot);
    onOpenCheckIn?.call();
  }
}
