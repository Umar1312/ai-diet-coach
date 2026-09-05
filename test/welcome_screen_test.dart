import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/welcome_screen.dart';

void main() {
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('welcome keeps actions usable at text scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('Login destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      );
      expect(find.text('Build my plan').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Review the change. Keep what works.'),
        150,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Build my plan').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Build my plan'));
      await tester.pumpAndSettle();
      expect(find.text('Login destination'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('Login destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
