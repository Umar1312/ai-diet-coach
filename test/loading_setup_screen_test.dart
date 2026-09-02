import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/loading_setup_screen.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=http://localhost');
  });

  testWidgets('setup failure remains usable on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    dio.httpClientAdapter = _SetupFailureAdapter();
    await tester.pumpWidget(const MaterialApp(home: LoadingSetupScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SetupFailureAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'error': {
          'code': 'internal_error',
          'message': 'An unexpected error occurred',
          'details': <String, dynamic>{},
        },
      }),
      500,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
