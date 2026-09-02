import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/main.dart' show dashboardStore;
import 'package:diet_coach_ai/presentation/widgets/proposal_sheet.dart';
import 'package:diet_coach_ai/shared/models/dashboard_state.dart';
import 'package:diet_coach_ai/shared/models/home_models.dart';
import 'package:diet_coach_ai/shared/models/meal.dart';
import 'package:diet_coach_ai/shared/models/planned_meal.dart';

void main() {
  testWidgets('proposal sheet scrolls five changes without overflowing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(dashboardStore.reset);
    dashboardStore.applyPlan(_planWithFiveChanges());

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  isDismissible: false,
                  enableDrag: false,
                  builder: (_) => const ProposalSheet(),
                ),
                child: const Text('Open proposal'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open proposal'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Accept Changes'), findsOneWidget);
    final actionY = tester.getCenter(find.text('Accept Changes')).dy;
    expect(actionY, lessThan(667));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(find.text('New late meal'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Accept Changes')).dy,
      closeTo(actionY, 1),
    );
    expect(tester.takeException(), isNull);
  });
}

DailyPlan _planWithFiveChanges() {
  const slots = ['breakfast', 'lunch', 'snack', 'dinner', 'late'];
  final currentMeals = <PlannedMeal>[
    for (var index = 0; index < slots.length; index++)
      _plannedMeal(slots[index], index, 'Current ${slots[index]} meal'),
  ];
  final changedMeals = <PlannedMeal>[
    for (var index = 0; index < slots.length; index++)
      _plannedMeal(slots[index], index, 'New ${slots[index]} meal'),
  ];

  return DailyPlan(
    dayId: '2026-09-02',
    userId: 'proposal-test-user',
    targets: const MacroTargets(
      calories: 2000,
      proteinG: 140,
      carbsG: 220,
      fatsG: 65,
    ),
    consumed: const MacroTargets(
      calories: 845,
      proteinG: 25,
      carbsG: 95,
      fatsG: 42,
    ),
    meals: const [],
    plannedMeals: currentMeals,
    pendingProposal: ProposedPlan(
      changedSlots: changedMeals,
      reason:
          'The logged meal was already high in calories and fat, so the '
          'remaining slots stay balanced with moderate protein and controlled '
          'added oil.',
    ),
    dayStatus: DayStatus.onTrack,
    aiCardText: 'Plan adjusted',
    aiCardState: AICardState.onTrack,
    generatedAt: '2026-09-02T09:00:00Z',
  );
}

PlannedMeal _plannedMeal(String slot, int order, String name) {
  return PlannedMeal(
    slot: slot,
    order: order,
    meal: Meal(
      name: name,
      emoji: '🍽️',
      calories: 350 + (order * 75),
      proteinG: 20,
      carbsG: 45,
      fatsG: 12,
    ),
    status: PlannedMealStatus.planned,
  );
}
