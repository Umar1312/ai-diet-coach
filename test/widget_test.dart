import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/presentation/screens/onboarding/pantry_intro_screen.dart';
import 'package:diet_coach_ai/presentation/screens/onboarding/food_location_screen.dart';
import 'package:diet_coach_ai/shared/models/user_setup_request.dart';

void main() {
  testWidgets('pantry onboarding intro fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: PantryIntroScreen()));

    expect(find.text('Meet your\nsmart pantry'), findsOneWidget);
    expect(find.text('Set up my pantry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('food location onboarding fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: FoodLocationScreen()));

    expect(find.text('What food feels\nlike home?'), findsOneWidget);
    expect(find.text('Your favorites'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('setup request sends canonical food preferences', () {
    const request = UserSetupRequest(
      gender: 'male',
      age: 28,
      heightCm: 175,
      weightKg: 78,
      activityLevel: 'moderate',
      goal: 'lose_weight',
      targetWeightKg: 72,
      dietaryRestrictions: [],
      country: 'IN',
      preferredCuisines: ['Mughlai', 'North Indian'],
    );

    expect(request.toJson()['country'], 'IN');
    expect(request.toJson()['preferred_cuisines'], ['Mughlai', 'North Indian']);
  });
}
