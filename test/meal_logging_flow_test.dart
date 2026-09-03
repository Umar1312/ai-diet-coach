import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/features/log_meal/food_search_screen.dart';
import 'package:diet_coach_ai/features/log_meal/meal_log_screen.dart';
import 'package:diet_coach_ai/features/log_meal/stores/meal_logging_store.dart';
import 'package:diet_coach_ai/features/meal_impact/meal_impact_screen.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/food_item.dart';
import 'package:diet_coach_ai/shared/models/home_models.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/meal_log_response.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost');
  });

  test('food search explicitly excludes pantry ingredients', () async {
    final adapter = _RecordingAdapter({
      'items': [_foodJson],
      'total': 1,
      'page': 1,
      'page_size': 20,
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;

    await ApiService(
      dio,
    ).searchFoods(q: 'egg', source: 'catalog', pageSize: 20);

    expect(adapter.lastRequest?.method, 'GET');
    expect(adapter.lastRequest?.path, '/foods/search');
    expect(adapter.lastRequest?.queryParameters, {
      'q': 'egg',
      'source': 'catalog',
      'page': 1,
      'page_size': 20,
    });
  });

  testWidgets('meal log starts with every item in today’s plan', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dashboard = DashboardStore()..applyPlan(_dailyPlan());
    final logging = MealLoggingStore(
      apiService: ApiService(Dio(BaseOptions(baseUrl: 'http://localhost'))),
      dashboardStore: dashboard,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MealLogScreen(
          store: dashboard,
          loggingStore: logging,
          refreshOnOpen: false,
        ),
      ),
    );

    expect(find.text('Today’s plan'), findsOneWidget);
    expect(find.text('Oats and berries'), findsOneWidget);
    expect(find.text('Paneer wrap'), findsOneWidget);
    expect(find.text('I ate something else'), findsOneWidget);
    expect(find.text('Your pantry'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Dal rice'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dal rice'), findsOneWidget);
    expect(find.text('I ate something else'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ad-hoc screen shows searchable foods as one-tap log rows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dashboard = DashboardStore();
    final logging = MealLoggingStore(
      apiService: ApiService(Dio(BaseOptions(baseUrl: 'http://localhost'))),
      dashboardStore: dashboard,
    );

    await tester.pumpWidget(
      MaterialApp(home: FoodSearchScreen(store: logging)),
    );
    logging.setQuery('egg');
    logging.results.add(FoodItem.fromJson(_foodJson));
    await tester.pump();

    expect(find.text('Find what you ate'), findsOneWidget);
    expect(find.text('Search food or dish'), findsOneWidget);
    expect(find.text('Boiled Egg'), findsOneWidget);
    expect(find.text('1 egg'), findsOneWidget);
    expect(find.text('78 cal  ·  6g protein'), findsOneWidget);
    expect(find.text('Can’t find it?'), findsOneWidget);
    expect(find.text('Your pantry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the impact loader before meal logging finishes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dashboard = _DeferredDashboardStore()..applyPlan(_dailyPlan());
    final logging = MealLoggingStore(
      apiService: ApiService(Dio(BaseOptions(baseUrl: 'http://localhost'))),
      dashboardStore: dashboard,
    );
    final router = GoRouter(
      initialLocation: '/log',
      routes: [
        GoRoute(
          path: '/log',
          builder: (_, _) => MealLogScreen(
            store: dashboard,
            loggingStore: logging,
            refreshOnOpen: false,
          ),
        ),
        GoRoute(
          path: '/meal-impact',
          builder: (_, _) =>
              MealImpactScreen(store: dashboard, loggingStore: logging),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paneer wrap'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => dashboard.started.future.timeout(const Duration(seconds: 2)),
    );

    expect(dashboard.lastMeal?.name, 'Paneer wrap');
    expect(dashboard.lastSource, 'recommendation');
    expect(dashboard.lastSlot, 'lunch');
    expect(router.state.uri.path, '/meal-impact');
    expect(logging.isLogging, isTrue);
    expect(find.text('MEAL RECEIVED'), findsOneWidget);
    expect(find.text('Logging Paneer wrap…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(dashboard.lastLoggedMeal.value, isNull);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      dashboard.complete(MealLogResponse.fromJson(_mealLogResponseJson()));
      while (logging.isLogging) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('MEAL LOGGED'), findsOneWidget);
    expect(find.text('You’re still\non track.'), findsOneWidget);
    expect(dashboard.lastLoggedMeal.value?.meal.name, 'Paneer wrap');
    expect(tester.takeException(), isNull);
  });
}

DailyPlan _dailyPlan() => DailyPlan(
  dayId: '2026-09-03',
  userId: 'user-1',
  targets: const MacroTargets(
    calories: 2100,
    proteinG: 150,
    carbsG: 230,
    fatsG: 68,
  ),
  consumed: const MacroTargets(
    calories: 410,
    proteinG: 21,
    carbsG: 58,
    fatsG: 12,
  ),
  meals: const [],
  plannedMeals: const [
    PlannedMeal(
      slot: 'breakfast',
      order: 0,
      meal: Meal(
        name: 'Oats and berries',
        emoji: '🥣',
        calories: 410,
        proteinG: 21,
        carbsG: 58,
        fatsG: 12,
      ),
      status: PlannedMealStatus.logged,
    ),
    PlannedMeal(
      slot: 'lunch',
      order: 1,
      meal: Meal(
        name: 'Paneer wrap',
        emoji: '🌯',
        calories: 520,
        proteinG: 34,
        carbsG: 52,
        fatsG: 20,
      ),
      status: PlannedMealStatus.planned,
    ),
    PlannedMeal(
      slot: 'snack',
      order: 2,
      meal: Meal(
        name: 'Greek yogurt',
        emoji: '🥛',
        calories: 210,
        proteinG: 20,
        carbsG: 22,
        fatsG: 5,
      ),
      status: PlannedMealStatus.planned,
      isOptional: true,
    ),
    PlannedMeal(
      slot: 'dinner',
      order: 3,
      meal: Meal(
        name: 'Dal rice',
        emoji: '🍛',
        calories: 650,
        proteinG: 30,
        carbsG: 85,
        fatsG: 18,
      ),
      status: PlannedMealStatus.planned,
    ),
  ],
  dayStatus: DayStatus.onTrack,
  aiCardText: 'Your day is ready.',
  aiCardState: AICardState.onTrack,
  generatedAt: '2026-09-03T08:00:00Z',
);

const _foodJson = <String, dynamic>{
  'id': 'boiled-egg',
  'name': 'Boiled Egg',
  'emoji': '🥚',
  'category': 'prepared-dish',
  'serving_size': '1 egg',
  'calories': 78,
  'protein_g': 6,
  'carbs_g': 1,
  'fats_g': 5,
  'aliases': ['eggs'],
  'country': 'IN',
  'cuisines': ['Indian'],
  'dietary_tags': ['vegetarian'],
  'prep_minutes': 10,
  'source': 'catalog',
};

Map<String, dynamic> _mealJson({
  required String name,
  required String emoji,
  required int calories,
  required int protein,
  required int carbs,
  required int fats,
}) => {
  'name': name,
  'emoji': emoji,
  'prep_minutes': 10,
  'calories': calories,
  'protein_g': protein,
  'carbs_g': carbs,
  'fats_g': fats,
  'cuisine': null,
  'serving_size': null,
  'components': [],
};

Map<String, dynamic> _mealLogResponseJson() {
  final loggedMeal = {
    'id': 'log-1',
    'user_id': 'user-1',
    'day_id': '2026-09-03',
    'source': 'recommendation',
    'logged_at': '2026-09-03T13:00:00Z',
    'image_url': null,
    'meal': _mealJson(
      name: 'Paneer wrap',
      emoji: '🌯',
      calories: 520,
      protein: 34,
      carbs: 52,
      fats: 20,
    ),
  };
  return {
    'log': loggedMeal,
    'updated_plan': {
      'day_id': '2026-09-03',
      'user_id': 'user-1',
      'targets': {
        'calories': 2100,
        'protein_g': 150,
        'carbs_g': 230,
        'fats_g': 68,
      },
      'consumed': {
        'calories': 930,
        'protein_g': 55,
        'carbs_g': 110,
        'fats_g': 32,
      },
      'meals': [loggedMeal],
      'planned_meals': [
        {
          'slot': 'dinner',
          'order': 3,
          'meal': _mealJson(
            name: 'Dal rice',
            emoji: '🍛',
            calories: 650,
            protein: 30,
            carbs: 85,
            fats: 18,
          ),
          'status': 'planned',
          'is_optional': false,
        },
      ],
      'pending_proposal': null,
      'next_meal': null,
      'recalibration': null,
      'day_status': 'on_track',
      'ai_card_text': 'You are still in a workable range.',
      'ai_card_state': 'on_track',
      'generated_at': '2026-09-03T13:00:00Z',
    },
  };
}

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

class _DeferredDashboardStore extends DashboardStore {
  final _response = Completer<MealLogResponse>();
  final started = Completer<void>();
  Meal? lastMeal;
  String? lastSource;
  String? lastSlot;

  @override
  Future<MealLogResponse> addMeal(
    Meal meal, {
    String source = 'text',
    String? slot,
  }) async {
    lastMeal = meal;
    lastSource = source;
    lastSlot = slot;
    if (!started.isCompleted) started.complete();
    final response = await _response.future;
    applyMealLogResponse(response);
    return response;
  }

  void complete(MealLogResponse response) => _response.complete(response);
}
