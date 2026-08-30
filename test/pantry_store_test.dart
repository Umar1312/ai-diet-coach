import 'package:flutter_test/flutter_test.dart';

import 'package:diet_coach_ai/features/pantry/stores/pantry_store.dart';
import 'package:diet_coach_ai/shared/models/home_models.dart';
import 'package:diet_coach_ai/shared/models/pantry_models.dart';

void main() {
  test('starter picker excludes items already present in the pantry', () {
    final store = PantryStore();
    store.items.add(
      const PantryItem(id: '1', name: ' Greek   Yogurt ', emoji: '🥣'),
    );
    store.starterPack.addAll([
      _starter(name: 'greek yogurt', category: 'Protein'),
      _starter(name: 'Eggs', category: 'Protein'),
    ]);

    final proteinItems = store.groupedStarters.value['Protein']!;

    expect(proteinItems.map((item) => item.name), ['Eggs']);
  });

  test('existing pantry items cannot remain selected for bulk add', () {
    final store = PantryStore();
    final starter = _starter(name: 'Eggs', category: 'Protein');
    store.starterPack.add(starter);
    store.selectedStarterNames.add(starter.name);

    store.items.add(const PantryItem(id: '1', name: 'eggs', emoji: '🥚'));

    expect(store.selectedCount.value, 0);
    expect(store.groupedStarters.value, isEmpty);
  });
}

PantryStarterItem _starter({required String name, required String category}) {
  return PantryStarterItem(
    name: name,
    emoji: '🥚',
    isHighProtein: true,
    calories: 100,
    proteinG: 10,
    carbsG: 1,
    fatsG: 5,
    category: category,
    tags: const [],
  );
}
