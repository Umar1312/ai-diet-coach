import 'package:mobx/mobx.dart';
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
  double loadingProgress = 0.0;

  @observable
  String loadingStatus = 'Calculating your macros...';

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
  void updateDietaryRestrictions(List<String> restrictions) {
    dietaryRestrictions = restrictions;
  }

  UserSetupRequest toApiRequest() {
    return UserSetupRequest(
      name: 'User',
      gender: gender ?? 'male',
      age: (age?.toInt()) ?? 25,
      heightCm: height ?? 175,
      weightKg: weight ?? 70,
      activityLevel: int.tryParse(activityLevel ?? '3') ?? 3,
      goal: goal ?? 'lose',
      targetWeightKg: targetWeight ?? 65,
      dietaryRestrictions: dietaryRestrictions,
    );
  }

  @action
  Future<void> calculatePlan() async {
    loadingProgress = 0.0;

    final steps = [
      'Calculating your BMR...',
      'Estimating your metabolic age...',
      'Analyzing activity level...',
      'Optimizing macro ratios...',
      'Creating your personalized plan...',
    ];

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      loadingStatus = steps[i];
      loadingProgress = (i + 1) / steps.length;
    }

    loadingProgress = 1.0;
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
    loadingProgress = 0.0;
    loadingStatus = 'Calculating your macros...';
  }
}
