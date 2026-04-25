import 'package:mobx/mobx.dart';
import '../core/constants/app_constants.dart';
import '../core/di/providers.dart';
import '../shared/models/user_setup_request.dart';

part 'onboarding_store.g.dart';

class OnboardingStore = _OnboardingStore with _$OnboardingStore;

abstract class _OnboardingStore with Store {
  @observable
  String? gender;

  @observable
  double? age;

  @observable
  double? height;

  @observable
  double? weight;

  @observable
  String? activityLevel;

  @observable
  String? goal;

  @observable
  double? targetWeight;

  @observable
  List<String> dietaryRestrictions = [];

  @observable
  String? country;

  @observable
  double loadingProgress = 0.0;

  @observable
  String loadingStatus = 'Calculating your macros...';

  @observable
  UserSetupResponse? setupResponse;

  @action
  void updateUser({
    double? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? goal,
    double? targetWeight,
  }) {
    if (age != null) this.age = age;
    if (weight != null) this.weight = weight;
    if (height != null) this.height = height;
    if (gender != null) this.gender = gender;
    if (activityLevel != null) this.activityLevel = activityLevel;
    if (goal != null) this.goal = goal;
    if (targetWeight != null) this.targetWeight = targetWeight;
  }

  @action
  void setCountry(String? value) {
    country = value;
  }

  @action
  void updateDietaryRestrictions(List<String> restrictions) {
    dietaryRestrictions = restrictions;
  }

  UserSetupRequest toApiRequest() {
    return UserSetupRequest(
      gender: (gender ?? 'male').toLowerCase(),
      age: (age?.toInt()) ?? 25,
      heightCm: height ?? 175,
      weightKg: weight ?? 70,
      activityLevel: AppConstants.activityLevelMap[activityLevel] ?? 'moderate',
      goal: AppConstants.goalMap[goal] ?? 'lose_weight',
      targetWeightKg: targetWeight ?? 65,
      dietaryRestrictions: dietaryRestrictions,
      country: country,
    );
  }

  @action
  Future<UserSetupResponse> calculatePlan() async {
    loadingProgress = 0.3;
    loadingStatus = 'Creating your profile...';

    final request = toApiRequest();
    final response = await apiService.setupUser(request);

    setupResponse = response;
    loadingProgress = 1.0;
    loadingStatus = 'Done!';
    return response;
  }

  @action
  void reset() {
    gender = null;
    age = null;
    height = null;
    weight = null;
    activityLevel = null;
    goal = null;
    targetWeight = null;
    dietaryRestrictions = [];
    country = null;
    loadingProgress = 0.0;
    loadingStatus = 'Calculating your macros...';
    setupResponse = null;
  }
}
