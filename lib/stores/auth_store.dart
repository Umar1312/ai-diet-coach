import 'package:mobx/mobx.dart';
import '../../core/di/providers.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  @observable
  String? firebaseToken;

  @observable
  bool isLoading = true;

  @action
  void setToken(String token) {
    firebaseToken = token;
    apiService.setAuthToken(token);
  }

  @action
  void setLoading(bool value) {
    isLoading = value;
  }

  @action
  void clearAuth() {
    firebaseToken = null;
    apiService.setAuthToken('');
  }
}
