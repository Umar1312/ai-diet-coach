import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/features/meal_swap/widgets/meal_swap_sheet.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost');
  });

  test('requests non-mutating alternatives with the selected intent', () async {
    final adapter = _RecordingAdapter({
      'slot_order': 1,
      'current_meal': _mealJson('Chicken salad', 500, 40),
      'alternatives': [
        {
          'meal': _mealJson('Paneer bowl', 480, 34),
          'why_it_fits': 'A quick high-protein alternative.',
          'used_pantry_items': ['Paneer'],
          'calorie_delta': -20,
          'protein_delta': -6,
          'carbs_delta': 10,
          'fats_delta': 2,
        },
      ],
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio);

    final response = await service.fetchSlotAlternatives(
      1,
      reason: 'quicker',
      excludeNames: const ['Chicken salad'],
      preferPantry: true,
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, '/day-plan/slots/1/alternatives');
    expect(adapter.lastRequest?.data, {
      'reason': 'quicker',
      'exclude_names': ['Chicken salad'],
      'count': 3,
      'prefer_pantry': true,
    });
    expect(response.alternatives.single.meal.name, 'Paneer bowl');
    expect(response.alternatives.single.usedPantryItems, ['Paneer']);
  });

  test('replaces one slot with an explicit rebalance choice', () async {
    final adapter = _RecordingAdapter({
      'updated_plan': _planJson(),
      'impact': {
        'calorie_delta': 80,
        'protein_delta': 5,
        'carbs_delta': 8,
        'fats_delta': 2,
        'changed_slots': [],
        'message': 'Only this meal changed.',
      },
      'requires_confirmation': false,
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio);
    final replacement = Meal.fromJson(_mealJson('Paneer bowl', 580, 45));

    final response = await service.replacePlanSlot(
      1,
      expectedCurrentName: 'Chicken salad',
      replacement: replacement,
      rebalanceRemaining: true,
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, '/day-plan/slots/1/replace');
    final data = adapter.lastRequest?.data as Map<String, dynamic>;
    expect(data['expected_current_name'], 'Chicken salad');
    expect(data['rebalance_remaining'], true);
    expect((data['meal'] as Map<String, dynamic>)['name'], 'Paneer bowl');
    expect(response.impact.calorieDelta, 80);
    expect(response.updatedPlan.plannedMeals.single.meal.name, 'Paneer bowl');
  });

  testWidgets('guided alternatives and review fit a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    dio.httpClientAdapter = _RecordingAdapter({
      'slot_order': 1,
      'current_meal': _mealJson('Chicken salad', 500, 40),
      'alternatives': [
        {
          'meal': _mealJson('Paneer bowl', 480, 34),
          'why_it_fits': 'A quick high-protein alternative.',
          'used_pantry_items': ['Paneer'],
          'calorie_delta': -20,
          'protein_delta': -6,
          'carbs_delta': 10,
          'fats_delta': 2,
        },
      ],
    });
    final plannedMeal = PlannedMeal(
      slot: 'lunch',
      order: 1,
      meal: Meal.fromJson(_mealJson('Chicken salad', 500, 40)),
      status: PlannedMealStatus.planned,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    showMealSwapSheet(context, plannedMeal: plannedMeal),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Change this meal'), findsOneWidget);
    expect(find.text('Paneer bowl'), findsOneWidget);
    expect(find.text('Choose my own'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Paneer bowl'));
    await tester.pumpAndSettle();

    expect(find.text('Review your change'), findsOneWidget);
    expect(find.text('CURRENT MEAL'), findsOneWidget);
    expect(find.text('REPLACE WITH'), findsOneWidget);
    expect(find.text('NEW MEAL'), findsOneWidget);
    expect(find.text('Replace and rebalance my day'), findsOneWidget);
    expect(find.text('Replace without rebalancing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _mealJson(String name, int calories, int protein) => {
  'name': name,
  'emoji': '🍽️',
  'prep_minutes': 15,
  'calories': calories,
  'protein_g': protein,
  'carbs_g': 45,
  'fats_g': 15,
  'cuisine': null,
  'serving_size': null,
  'components': [],
};

Map<String, dynamic> _planJson() => {
  'day_id': '2026-08-23',
  'user_id': 'test-user',
  'targets': {'calories': 2100, 'protein_g': 150, 'carbs_g': 230, 'fats_g': 65},
  'consumed': {'calories': 0, 'protein_g': 0, 'carbs_g': 0, 'fats_g': 0},
  'meals': [],
  'planned_meals': [
    {
      'slot': 'lunch',
      'order': 1,
      'meal': _mealJson('Paneer bowl', 580, 45),
      'status': 'planned',
      'is_optional': false,
    },
  ],
  'pending_proposal': null,
  'next_meal': null,
  'recalibration': {
    'mode': 'balanced',
    'title': 'On track',
    'detail': 'Ready for the day',
  },
  'day_status': 'on_track',
  'ai_card_text': 'Ready for the day',
  'ai_card_state': 'on_track',
  'generated_at': '2026-08-23T10:00:00Z',
};

class _RecordingAdapter implements HttpClientAdapter {
  final Map<String, dynamic> responseJson;
  RequestOptions? lastRequest;

  _RecordingAdapter(this.responseJson);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(responseJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
