import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/presentation/screens/plan/plan_screen.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';

class _DelayedLogAdapter implements HttpClientAdapter {
  final Map<String, dynamic> plan;
  final requests = <RequestOptions>[];
  final allRequests = <RequestOptions>[];
  Completer<ResponseBody> pending = Completer<ResponseBody>();
  _DelayedLogAdapter(this.plan);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    allRequests.add(options);
    if (options.method == 'POST') {
      requests.add(options);
      return pending.future;
    }
    return ResponseBody.fromString(
      jsonEncode(options.path == '/pantry' ? {'items': []} : plan),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  void fail() => pending.complete(
    ResponseBody.fromString(
      jsonEncode({
        'error': {'code': 'unavailable', 'message': 'Please try again.'},
      }),
      503,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=http://localhost'));

  testWidgets('plan screen reuses dashboard state loaded for today', (
    tester,
  ) async {
    final plan =
        jsonDecode(File('test/fixtures/adaptive_plan.json').readAsStringSync())
            as Map<String, dynamic>;
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    plan['day_id'] = '${now.year}-${two(now.month)}-${two(now.day)}';

    final adapter = _DelayedLogAdapter(plan);
    final originalAdapter = dio.httpClientAdapter;
    dio.httpClientAdapter = adapter;
    dashboardStore.applyPlan(DailyPlan.fromJson(plan));
    addTearDown(() {
      dio.httpClientAdapter = originalAdapter;
      dashboardStore.reset();
    });

    await tester.pumpWidget(const MaterialApp(home: PlanScreen()));
    await tester.pump();

    expect(adapter.allRequests, isEmpty);
    expect(find.text('Dal rice'), findsOneWidget);
  });

  testWidgets(
    'confirmation shows loading, prevents duplicates, and allows retry after failure',
    (tester) async {
      final plan =
          jsonDecode(
                File('test/fixtures/adaptive_plan.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final adapter = _DelayedLogAdapter(plan);
      final originalAdapter = dio.httpClientAdapter;
      dio.httpClientAdapter = adapter;
      addTearDown(() {
        dio.httpClientAdapter = originalAdapter;
        dashboardStore.reset();
      });
      await tester.pumpWidget(const MaterialApp(home: PlanScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, I ate this'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Yes, I ate this'), findsNothing);
      await tester.tap(find.byType(CircularProgressIndicator));
      for (var i = 0; i < 10 && adapter.requests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(adapter.requests, hasLength(1));
      adapter.fail();
      await tester.pumpAndSettle();
      expect(find.text('Yes, I ate this'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      adapter.pending = Completer<ResponseBody>();
      await tester.tap(find.text('Yes, I ate this'));
      for (var i = 0; i < 10 && adapter.requests.length < 2; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests[1].data['operation_id'],
        adapter.requests[0].data['operation_id'],
      );
      adapter.fail();
      await tester.pumpAndSettle();
    },
  );
}
