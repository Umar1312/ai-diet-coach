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

  Future<void> submit() async {
    final text = description.value.trim();
    if (text.isEmpty || isSubmitting.value) return;

    runInAction(() {
      isSubmitting.value = true;
      errorMessage.value = null;
    });

    try {
      final response = await apiService.logText(text);
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

  void clear() {
    runInAction(() {
      description.value = '';
      isSubmitting.value = false;
      errorMessage.value = null;
    });
  }
}
