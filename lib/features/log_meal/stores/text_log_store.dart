import 'package:mobx/mobx.dart';
import '../../../core/di/providers.dart';
import '../../../main.dart' show dashboardStore;

/// MobX store WITHOUT codegen.
/// All observables/computed are declared manually via Observable()/Computed().
class TextLogStore {
  // ── Core fields ─────────────────────────────────────────────────────────

  final description = Observable<String>('');
  final isSubmitting = Observable<bool>(false);
  final errorMessage = Observable<String?>(null);

  /// Pantry item IDs the user explicitly tapped while composing the log.
  final selectedPantryItemIds = ObservableList<String>();

  // ── Computed ────────────────────────────────────────────────────────────

  late final canSubmit = Computed<bool>(
    () => description.value.trim().isNotEmpty && !isSubmitting.value,
  );

  // ── Actions ─────────────────────────────────────────────────────────────

  void setDescription(String value) {
    runInAction(() {
      description.value = value;
      if (errorMessage.value != null) errorMessage.value = null;
    });
  }

  Future<void> submit({String? slot}) async {
    final text = description.value.trim();
    if (text.isEmpty || isSubmitting.value) return;

    runInAction(() {
      isSubmitting.value = true;
      errorMessage.value = null;
    });

    try {
      final response = await apiService.logText(
        text,
        pantryItemIds: selectedPantryItemIds.isEmpty
            ? null
            : selectedPantryItemIds.toList(),
        slot: slot,
      );
      dashboardStore.applyPlan(response.updatedPlan);
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (e) {
      runInAction(
        () => errorMessage.value = 'Failed to log meal. Please try again.',
      );
    } finally {
      runInAction(() => isSubmitting.value = false);
    }
  }

  void togglePantryItem(String itemId) {
    runInAction(() {
      if (selectedPantryItemIds.contains(itemId)) {
        selectedPantryItemIds.remove(itemId);
      } else {
        selectedPantryItemIds.add(itemId);
      }
    });
  }

  void clear() {
    runInAction(() {
      description.value = '';
      isSubmitting.value = false;
      errorMessage.value = null;
      selectedPantryItemIds.clear();
    });
  }
}
