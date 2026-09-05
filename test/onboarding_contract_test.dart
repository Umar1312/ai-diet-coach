import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/shared/models/onboarding_state.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost');
  });

  test('pantry completion sends only canonical starter names', () async {
    final adapter = _RecordingAdapter({
      'id': 'plan-1',
      'revision': 1,
      'context_version': 'context-1',
      'adaptation_status': 'idle',
      'adaptation_access': {
        'is_pro': false,
        'allowance_total': 3,
        'accepted_count': 0,
        'remaining': 3,
        'can_accept': true,
      },
      'onboarding_stage': 'plan_preview',
      'pantry_decision': 'selected',
      'onboarding_completed_at': null,
      'items_added': 2,
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio);

    final response = await service.completeOnboardingPantry(
      skipped: false,
      selectedItemNames: const ['Paneer', 'Rice'],
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, '/users/onboarding/pantry-complete');
    expect(adapter.lastRequest?.data, {
      'decision': 'selected',
      'selected_item_names': ['Paneer', 'Rice'],
    });
    expect(response.stage, OnboardingStage.planPreview);
    expect(response.itemsAdded, 2);
  });

  test('starter pack uses the pre-paywall onboarding endpoint', () async {
    final adapter = _RecordingAdapter({
      'country': 'IN',
      'country_name': 'India',
      'items': [
        {
          'id': 'breakfast-slot',
          'name': 'Paneer',
          'emoji': '🧀',
          'quantity_hint': '200g block',
          'is_high_protein': true,
          'calories': 265,
          'protein_g': 18,
          'carbs_g': 6,
          'fats_g': 20,
          'serving_size': '100g',
          'category': 'Protein Sources',
          'tags': ['vegetarian', 'dairy'],
        },
      ],
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio);

    final response = await service.fetchOnboardingStarterPack();

    expect(adapter.lastRequest?.method, 'GET');
    expect(adapter.lastRequest?.path, '/users/onboarding/pantry-starter-pack');
    expect(response.items.single.name, 'Paneer');
  });

  test('final completion uses the ungated onboarding endpoint', () async {
    final adapter = _RecordingAdapter({
      'onboarding_stage': 'complete',
      'pantry_decision': 'skipped',
      'onboarding_completed_at': '2026-08-16T10:02:00Z',
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio);

    final response = await service.completeOnboarding();

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, '/users/onboarding/complete');
    expect(response.stage, OnboardingStage.complete);
    expect(response.completedAt, DateTime.utc(2026, 8, 16, 10, 2));
  });

  test('plan preview uses its pre-paywall generation endpoint', () async {
    final adapter = _RecordingAdapter({
      'id': 'plan-1',
      'revision': 1,
      'context_version': 'context-1',
      'adaptation_status': 'idle',
      'adaptation_access': {
        'is_pro': false,
        'allowance_total': 3,
        'accepted_count': 0,
        'remaining': 3,
        'can_accept': true,
      },
      'day_id': '2026-08-16',
      'user_id': 'test-user',
      'targets': {
        'calories': 2100,
        'protein_g': 150,
        'carbs_g': 230,
        'fats_g': 65,
      },
      'consumed': {'calories': 0, 'protein_g': 0, 'carbs_g': 0, 'fats_g': 0},
      'meals': [],
      'planned_meals': [
        {
          'id': 'breakfast-slot',
          'slot': 'breakfast',
          'order': 0,
          'meal': {
            'name': 'Paneer scramble',
            'emoji': '🍳',
            'prep_minutes': 12,
            'calories': 420,
            'protein_g': 29,
            'carbs_g': 18,
            'fats_g': 25,
          },
          'status': 'planned',
          'is_optional': false,
          'is_protected': false,
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
      'generated_at': '2026-08-16T10:00:00Z',
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio);

    final response = await service.fetchOnboardingPlanPreview();

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, '/users/onboarding/plan-preview');
    expect(response.plannedMeals.single.meal.name, 'Paneer scramble');
  });
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
