import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:diet_coach_ai/shared/models/planned_meal.dart';

typedef MealNotificationTap = void Function(String slot);

/// iOS-only local notification scheduler for daily meal check-ins.
class MealNotificationService {
  static const _payloadPrefix = 'meal-check-in:';
  static const _channelId = 'meal_check_ins';
  static const _slotIds = <String, int>{
    'breakfast': 4101,
    'lunch': 4102,
    'snack': 4103,
    'dinner': 4104,
    'late': 4105,
  };

  final FlutterLocalNotificationsPlugin _plugin;
  MealNotificationTap? onTap;
  String? initialSlot;
  bool _initialized = false;
  String? timezoneError;

  MealNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    tz_data.initializeTimeZones();
    await refreshTimezone();

    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      initialSlot = _slotFromPayload(
        launchDetails?.notificationResponse?.payload,
      );
    }
    _initialized = true;
  }

  Future<void> refreshTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      timezoneError = null;
    } catch (e) {
      timezoneError = 'Could not read the device timezone: $e';
    }
  }

  Future<NotificationsEnabledOptions?> permissions() async {
    if (!isSupported) return null;
    await initialize();
    return _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
  }

  Future<String> diagnostics() async {
    if (!isSupported) {
      return 'Local check-ins are currently supported on iOS only.';
    }
    final permission = await permissions();
    final pending = await _plugin.pendingNotificationRequests();
    final reminders = pending.where(
      (item) => item.payload?.startsWith(_payloadPrefix) ?? false,
    );
    return 'Permission: ${permission?.isEnabled}\nAlerts: ${permission?.isAlertEnabled}'
        '\nSound: ${permission?.isSoundEnabled}\nTimezone: ${tz.local.name}'
        '\nPending check-ins: ${reminders.length}'
        '\nSlots: ${reminders.map((item) => item.payload!.substring(_payloadPrefix.length)).join(', ')}'
        '\nRegistration: local notifications; no push token required.'
        '${timezoneError == null ? '' : '\n$timezoneError'}';
  }

  Future<void> testCheckIn(String slot) async {
    if (!isSupported) throw StateError('Check-in notifications require iOS.');
    await initialize();
    if (!((await permissions())?.isEnabled ?? false)) {
      if (!await requestPermission()) {
        throw StateError(
          'Notification permission was denied. Enable it in iPhone Settings.',
        );
      }
    }
    await _plugin.show(
      id: 4199,
      title: '🍽️ Test check-in',
      body: 'Your check-in test is ready. Tap to open it.',
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          threadIdentifier: _channelId,
        ),
      ),
      payload: '$_payloadPrefix$slot',
    );
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: true) ??
        false;
  }

  Future<void> syncDailyReminders({
    required bool enabled,
    required Map<String, int> times,
    required List<PlannedMeal> plannedMeals,
  }) async {
    if (!isSupported) return;
    await initialize();
    if (!enabled) {
      await cancelMealReminders();
      return;
    }
    await refreshTimezone();
    if (timezoneError != null) throw StateError(timezoneError!);
    if (!((await permissions())?.isEnabled ?? false)) {
      throw StateError('Notifications are disabled in iPhone Settings.');
    }

    final mealsBySlot = <String, PlannedMeal>{
      for (final meal in plannedMeals) meal.slot: meal,
    };
    // Replace matching IDs without a cancel-all gap. Preserve snoozes for
    // outstanding meals across unrelated plan refreshes.
    for (final entry in _slotIds.entries) {
      final meal = mealsBySlot[entry.key];
      if (meal == null) await _plugin.cancel(id: entry.value);
      if (meal == null || meal.status != PlannedMealStatus.planned) {
        await _plugin.cancel(id: entry.value + 100);
      }
    }
    for (final entry in mealsBySlot.entries) {
      final id = _slotIds[entry.key];
      final minuteOfDay = times[entry.key];
      if (id == null || minuteOfDay == null) continue;

      final meal = entry.value;
      final firstDelivery = _nextDelivery(
        minuteOfDay,
        forceTomorrow: meal.status != PlannedMealStatus.planned,
      );
      await _plugin.zonedSchedule(
        id: id,
        title: '${_slotEmoji(entry.key)} ${_slotLabel(entry.key)} check-in',
        body: 'Did you eat your planned ${entry.key} meal?',
        scheduledDate: firstDelivery,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            threadIdentifier: _channelId,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$_payloadPrefix${entry.key}',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> snooze(
    String slot, {
    Duration delay = const Duration(minutes: 30),
  }) async {
    if (!isSupported) return;
    await initialize();
    final baseId = _slotIds[slot];
    if (baseId == null) return;
    await _plugin.zonedSchedule(
      id: baseId + 100,
      title: '${_slotEmoji(slot)} ${_slotLabel(slot)} check-in',
      body: 'Ready to check in on your planned $slot meal?',
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          threadIdentifier: _channelId,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$_payloadPrefix$slot',
    );
  }

  Future<void> cancelMealReminders() async {
    if (!isSupported) return;
    for (final id in _slotIds.values) {
      await _plugin.cancel(id: id);
      await _plugin.cancel(id: id + 100);
    }
  }

  tz.TZDateTime _nextDelivery(int minuteOfDay, {bool forceTomorrow = false}) {
    final now = tz.TZDateTime.now(tz.local);
    var delivery = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (forceTomorrow || !delivery.isAfter(now)) {
      delivery = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        minuteOfDay ~/ 60,
        minuteOfDay % 60,
      );
    }
    return delivery;
  }

  void _handlePayload(String? payload) {
    final slot = _slotFromPayload(payload);
    if (slot == null) return;
    onTap?.call(slot);
  }

  String? _slotFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    final slot = payload.substring(_payloadPrefix.length);
    return _slotIds.containsKey(slot) ? slot : null;
  }

  String _slotLabel(String slot) => switch (slot) {
    'breakfast' => 'Breakfast',
    'lunch' => 'Lunch',
    'snack' => 'Snack',
    'dinner' => 'Dinner',
    'late' => 'Late meal',
    _ => 'Meal',
  };

  String _slotEmoji(String slot) => switch (slot) {
    'breakfast' => '🌅',
    'lunch' => '🌞',
    'snack' => '🍎',
    'dinner' => '🌙',
    'late' => '🌃',
    _ => '🍽️',
  };
}
