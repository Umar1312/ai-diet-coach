import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diet_coach_ai/shared/widgets/stepper_slider.dart';
import 'package:diet_coach_ai/shared/widgets/nextmeal_app_icon.dart';
import 'package:diet_coach_ai/presentation/screens/splash/splash_screen.dart';
import 'package:diet_coach_ai/core/services/meal_notification_service.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/notification_store.dart';

class _UnusedPreferences implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailOnceService extends MealNotificationService {
  int calls = 0;
  @override
  Future<void> syncDailyReminders({
    required bool enabled,
    required Map<String, int> times,
    required List<PlannedMeal> plannedMeals,
  }) async {
    if (++calls == 1) throw StateError('Transient scheduling failure');
  }
}

void main() {
  test('notification queue recovers after a failed sync', () async {
    final service = _FailOnceService();
    final store = NotificationStore(
      service: service,
      preferences: _UnusedPreferences(),
    );
    await store.syncWithPlan([]);
    expect(store.syncError.value, isNotEmpty);
    await store.syncWithPlan([]);
    expect(service.calls, 2);
    expect(store.syncError.value, isEmpty);
  });

  testWidgets('step buttons clamp, disable at bounds, and support decimals', (
    tester,
  ) async {
    var value = .9;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) => Scaffold(
            body: StepperSlider(
              value: value,
              min: 0,
              max: 1,
              step: .1,
              semanticLabel: 'weight',
              onChanged: (next) => update(() => value = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Increase weight'));
    await tester.pump();
    expect(value, 1);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Increase weight',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Decrease weight'));
    await tester.pump();
    expect(value, .9);
  });

  testWidgets('narrow slider keeps both 48px targets without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 140,
            child: StepperSlider(value: 5, min: 3, max: 8, onChanged: (_) {}),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final button in find.byType(IconButton).evaluate()) {
      expect(
        tester.getSize(find.byWidget(button.widget)).width,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets('splash fills progressively and completes exactly once', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onComplete: () => completed++)),
    );
    expect(
      tester
          .widget<NextMealAppIcon>(find.byType(NextMealAppIcon))
          .animationProgress,
      0,
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(
      tester
          .widget<NextMealAppIcon>(find.byType(NextMealAppIcon))
          .animationProgress,
      closeTo(.5, .01),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NextMealAppIcon>(find.byType(NextMealAppIcon))
          .animationProgress,
      1,
    );
    expect(completed, 1);
  });

  testWidgets('reduced motion shows the settled logo immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SplashScreen(),
        ),
      ),
    );
    expect(
      tester
          .widget<NextMealAppIcon>(find.byType(NextMealAppIcon))
          .animationProgress,
      1,
    );
    await tester.pumpAndSettle();
  });
}
