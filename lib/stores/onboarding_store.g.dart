// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OnboardingStore on _OnboardingStore, Store {
  late final _$genderAtom = Atom(
    name: '_OnboardingStore.gender',
    context: context,
  );

  @override
  String? get gender {
    _$genderAtom.reportRead();
    return super.gender;
  }

  @override
  set gender(String? value) {
    _$genderAtom.reportWrite(value, super.gender, () {
      super.gender = value;
    });
  }

  late final _$ageAtom = Atom(name: '_OnboardingStore.age', context: context);

  @override
  double? get age {
    _$ageAtom.reportRead();
    return super.age;
  }

  @override
  set age(double? value) {
    _$ageAtom.reportWrite(value, super.age, () {
      super.age = value;
    });
  }

  late final _$heightAtom = Atom(
    name: '_OnboardingStore.height',
    context: context,
  );

  @override
  double? get height {
    _$heightAtom.reportRead();
    return super.height;
  }

  @override
  set height(double? value) {
    _$heightAtom.reportWrite(value, super.height, () {
      super.height = value;
    });
  }

  late final _$weightAtom = Atom(
    name: '_OnboardingStore.weight',
    context: context,
  );

  @override
  double? get weight {
    _$weightAtom.reportRead();
    return super.weight;
  }

  @override
  set weight(double? value) {
    _$weightAtom.reportWrite(value, super.weight, () {
      super.weight = value;
    });
  }

  late final _$activityLevelAtom = Atom(
    name: '_OnboardingStore.activityLevel',
    context: context,
  );

  @override
  String? get activityLevel {
    _$activityLevelAtom.reportRead();
    return super.activityLevel;
  }

  @override
  set activityLevel(String? value) {
    _$activityLevelAtom.reportWrite(value, super.activityLevel, () {
      super.activityLevel = value;
    });
  }

  late final _$goalAtom = Atom(name: '_OnboardingStore.goal', context: context);

  @override
  String? get goal {
    _$goalAtom.reportRead();
    return super.goal;
  }

  @override
  set goal(String? value) {
    _$goalAtom.reportWrite(value, super.goal, () {
      super.goal = value;
    });
  }

  late final _$targetWeightAtom = Atom(
    name: '_OnboardingStore.targetWeight',
    context: context,
  );

  @override
  double? get targetWeight {
    _$targetWeightAtom.reportRead();
    return super.targetWeight;
  }

  @override
  set targetWeight(double? value) {
    _$targetWeightAtom.reportWrite(value, super.targetWeight, () {
      super.targetWeight = value;
    });
  }

  late final _$dietaryRestrictionsAtom = Atom(
    name: '_OnboardingStore.dietaryRestrictions',
    context: context,
  );

  @override
  List<String> get dietaryRestrictions {
    _$dietaryRestrictionsAtom.reportRead();
    return super.dietaryRestrictions;
  }

  @override
  set dietaryRestrictions(List<String> value) {
    _$dietaryRestrictionsAtom.reportWrite(value, super.dietaryRestrictions, () {
      super.dietaryRestrictions = value;
    });
  }

  late final _$loadingProgressAtom = Atom(
    name: '_OnboardingStore.loadingProgress',
    context: context,
  );

  @override
  double get loadingProgress {
    _$loadingProgressAtom.reportRead();
    return super.loadingProgress;
  }

  @override
  set loadingProgress(double value) {
    _$loadingProgressAtom.reportWrite(value, super.loadingProgress, () {
      super.loadingProgress = value;
    });
  }

  late final _$loadingStatusAtom = Atom(
    name: '_OnboardingStore.loadingStatus',
    context: context,
  );

  @override
  String get loadingStatus {
    _$loadingStatusAtom.reportRead();
    return super.loadingStatus;
  }

  @override
  set loadingStatus(String value) {
    _$loadingStatusAtom.reportWrite(value, super.loadingStatus, () {
      super.loadingStatus = value;
    });
  }

  late final _$setupResponseAtom = Atom(
    name: '_OnboardingStore.setupResponse',
    context: context,
  );

  @override
  UserSetupResponse? get setupResponse {
    _$setupResponseAtom.reportRead();
    return super.setupResponse;
  }

  @override
  set setupResponse(UserSetupResponse? value) {
    _$setupResponseAtom.reportWrite(value, super.setupResponse, () {
      super.setupResponse = value;
    });
  }

  late final _$calculatePlanAsyncAction = AsyncAction(
    '_OnboardingStore.calculatePlan',
    context: context,
  );

  @override
  Future<UserSetupResponse> calculatePlan() {
    return _$calculatePlanAsyncAction.run(() => super.calculatePlan());
  }

  late final _$_OnboardingStoreActionController = ActionController(
    name: '_OnboardingStore',
    context: context,
  );

  @override
  void updateUser({
    double? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? goal,
    double? targetWeight,
  }) {
    final _$actionInfo = _$_OnboardingStoreActionController.startAction(
      name: '_OnboardingStore.updateUser',
    );
    try {
      return super.updateUser(
        age: age,
        weight: weight,
        height: height,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
        targetWeight: targetWeight,
      );
    } finally {
      _$_OnboardingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateDietaryRestrictions(List<String> restrictions) {
    final _$actionInfo = _$_OnboardingStoreActionController.startAction(
      name: '_OnboardingStore.updateDietaryRestrictions',
    );
    try {
      return super.updateDietaryRestrictions(restrictions);
    } finally {
      _$_OnboardingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo = _$_OnboardingStoreActionController.startAction(
      name: '_OnboardingStore.reset',
    );
    try {
      return super.reset();
    } finally {
      _$_OnboardingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
gender: ${gender},
age: ${age},
height: ${height},
weight: ${weight},
activityLevel: ${activityLevel},
goal: ${goal},
targetWeight: ${targetWeight},
dietaryRestrictions: ${dietaryRestrictions},
loadingProgress: ${loadingProgress},
loadingStatus: ${loadingStatus},
setupResponse: ${setupResponse}
    ''';
  }
}
