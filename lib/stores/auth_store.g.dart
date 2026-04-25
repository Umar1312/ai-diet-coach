// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on _AuthStore, Store {
  late final _$firebaseTokenAtom = Atom(
    name: '_AuthStore.firebaseToken',
    context: context,
  );

  @override
  String? get firebaseToken {
    _$firebaseTokenAtom.reportRead();
    return super.firebaseToken;
  }

  @override
  set firebaseToken(String? value) {
    _$firebaseTokenAtom.reportWrite(value, super.firebaseToken, () {
      super.firebaseToken = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_AuthStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$_AuthStoreActionController = ActionController(
    name: '_AuthStore',
    context: context,
  );

  @override
  void setToken(String token) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.setToken',
    );
    try {
      return super.setToken(token);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLoading(bool value) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.setLoading',
    );
    try {
      return super.setLoading(value);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearAuth() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.clearAuth',
    );
    try {
      return super.clearAuth();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
firebaseToken: ${firebaseToken},
isLoading: ${isLoading}
    ''';
  }
}
