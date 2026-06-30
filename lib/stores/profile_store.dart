import 'package:mobx/mobx.dart';

import 'package:diet_coach_ai/core/di/providers.dart';
import 'package:diet_coach_ai/shared/models/user_setup_request.dart';
import 'package:diet_coach_ai/stores/dashboard_store.dart';

class ProfileStore {
  final DashboardStore dashboardStore;

  ProfileStore({required this.dashboardStore});

  final user = Observable<User?>(null);
  final isLoading = Observable<bool>(false);
  final isSaving = Observable<bool>(false);
  final errorMessage = Observable<String>('');

  Future<void> loadProfile({bool force = false}) async {
    if (isLoading.value || (!force && user.value != null)) return;

    runInAction(() {
      isLoading.value = true;
      errorMessage.value = '';
    });

    try {
      final profile = await apiService.fetchProfile();
      runInAction(() => user.value = profile);
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (_) {
      runInAction(() => errorMessage.value = 'Failed to load profile.');
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }

  Future<bool> updateProfile(ProfilePatchRequest request) async {
    if (isSaving.value) return false;

    runInAction(() {
      isSaving.value = true;
      errorMessage.value = '';
    });

    try {
      final updated = await apiService.updateProfile(request);
      runInAction(() => user.value = updated);
      await dashboardStore.refresh();
      return true;
    } on ApiException catch (e) {
      runInAction(() => errorMessage.value = e.message);
    } catch (_) {
      runInAction(() => errorMessage.value = 'Failed to update profile.');
    } finally {
      runInAction(() => isSaving.value = false);
    }
    return false;
  }

  void reset() {
    runInAction(() {
      user.value = null;
      isLoading.value = false;
      isSaving.value = false;
      errorMessage.value = '';
    });
  }
}
