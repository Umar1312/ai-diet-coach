# Flutter → Backend API Migration Plan

> **Purpose:** Migrate the Flutter app from mock-data to real backend consumption.
> **Source of truth:** `/Users/umarsalim/Developer/api_service_diet_coach_ai` backend contract.
> **Current state:** 100% mock data. `ApiService` defined but never imported or used.

---

## Phase 0: Foundation (Prerequisites)

### 0.1 Update `AppConstants`

File: `lib/core/constants/app_constants.dart`

**Change 1:** Activity level map → string values (backend expects `"sedentary"`, `"light"`, etc.)

```dart
// OLD
static const Map<String, int> activityLevelMap = {
  'Sedentary': 1,
  'Lightly Active': 2,
  'Moderately Active': 3,
  'Very Active': 4,
  'Extremely Active': 5,
};

// NEW
static const Map<String, String> activityLevelMap = {
  'Sedentary': 'sedentary',
  'Lightly Active': 'light',
  'Moderately Active': 'moderate',
  'Very Active': 'active',
  'Extremely Active': 'very_active',
};
```

**Change 2:** Goal map → new enum values

```dart
// OLD
static const Map<String, String> goalMap = {
  'Lose Weight': 'lose',
  'Maintain': 'maintain',
  'Gain Muscle': 'gain',
};

// NEW
static const Map<String, String> goalMap = {
  'Lose Weight': 'lose_weight',
  'Maintain': 'maintain',
  'Gain Muscle': 'gain_muscle',
};
```

**Change 3:** Remove `maxImageUploadBytes` (backend handles validation)

---

## Phase 1: Update API Models (`lib/shared/models/`)

### 1.1 `user_setup_request.dart`

**Changes:**
- Remove `name` field (backend doesn't require it)
- `activityLevel` type: `int` → `String`
- `goal` values: `"lose"` → `"lose_weight"`, etc.

```dart
class UserSetupRequest {
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String activityLevel;  // was int
  final String goal;
  final double targetWeightKg;
  final List<String> dietaryRestrictions;

  const UserSetupRequest({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.targetWeightKg,
    required this.dietaryRestrictions,
  });

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'age': age,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity_level': activityLevel,  // string now
    'goal': goal,
    'target_weight_kg': targetWeightKg,
    'dietary_restrictions': dietaryRestrictions,
  };
}
```

**New:** `UserSetupResponse` → parse `{user, plan}` wrapper

```dart
class UserSetupResponse {
  final User user;
  final DailyPlan plan;

  const UserSetupResponse({required this.user, required this.plan});

  factory UserSetupResponse.fromJson(Map<String, dynamic> json) =>
      UserSetupResponse(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        plan: DailyPlan.fromJson(json['plan'] as Map<String, dynamic>),
      );
}
```

---

### 1.2 `meal.dart`

**Changes:**
- Add `id`, `userId`, `dayId`
- Rename `protein` → `proteinG`, `carbs` → `carbsG`, `fats` → `fatsG`
- Keep `foodName`, `calories`, `imageUrl`, `loggedAt`, `source`

```dart
class Meal {
  final String id;
  final String userId;
  final String foodName;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final String? imageUrl;
  final String loggedAt;
  final String source;
  final String dayId;

  const Meal({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.imageUrl,
    required this.loggedAt,
    required this.source,
    required this.dayId,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    foodName: json['food_name'] as String,
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    carbsG: json['carbs_g'] as int,
    fatsG: json['fats_g'] as int,
    imageUrl: json['image_url'] as String?,
    loggedAt: json['logged_at'] as String,
    source: json['source'] as String,
    dayId: json['day_id'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'food_name': foodName,
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fats_g': fatsG,
    'image_url': imageUrl,
    'logged_at': loggedAt,
    'source': source,
    'day_id': dayId,
  };
}
```

**Impact:** Update all call sites that construct `Meal(...)` to pass `id`, `userId`, `dayId` and use `_g` field names. For mock data, use `id: ''`, `userId: ''`, `dayId: DateTime.now().toIso8601String().split('T')[0]`.

---

### 1.3 `dashboard_state.dart`

**CRITICAL:** This model needs a full rewrite. The UI depends on fields that aren't currently parsed.

**New fields to parse:**
- `day_id` (String)
- `user_id` (String)
- `targets` → nested `{calories, protein_g, carbs_g, fats_g}`
- `consumed` → nested `{calories, protein_g, carbs_g, fats_g}`
- `flex_plan` → List of `FlexPlanSlot` (from `home_models.dart`)
- `next_meal` → `NextMealRecommendation` (from `home_models.dart`)
- `recalibration` → `RecalibrationStatus` (from `home_models.dart`)
- `day_status` (String)
- `ai_card_text` (String)
- `ai_card_state` (String)
- `generated_at` (String)

```dart
class DashboardState {
  final String dayId;
  final String userId;
  final MacroTargets targets;
  final MacroTargets consumed;
  final List<Meal> meals;
  final List<FlexPlanSlot> flexPlan;
  final NextMealRecommendation? nextMeal;
  final RecalibrationStatus? recalibration;
  final DayStatus dayStatus;
  final String aiCardText;
  final AICardState aiCardState;
  final String generatedAt;

  const DashboardState({...});

  factory DashboardState.fromJson(Map<String, dynamic> json) => DashboardState(
    dayId: json['day_id'] as String,
    userId: json['user_id'] as String,
    targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
    consumed: MacroTargets.fromJson(json['consumed'] as Map<String, dynamic>),
    meals: (json['meals'] as List).map((e) => Meal.fromJson(e)).toList(),
    flexPlan: (json['flex_plan'] as List)
        .map((e) => FlexPlanSlot.fromJson(e as Map<String, dynamic>))
        .toList(),
    nextMeal: json['next_meal'] == null
        ? null
        : NextMealRecommendation.fromJson(json['next_meal'] as Map<String, dynamic>),
    recalibration: json['recalibration'] == null
        ? null
        : RecalibrationStatus.fromJson(json['recalibration'] as Map<String, dynamic>),
    dayStatus: DayStatus.values.firstWhere(
      (e) => e.name == (json['day_status'] as String).replaceAll('_', ''),
      orElse: () => DayStatus.onTrack,
    ),
    aiCardText: json['ai_card_text'] as String,
    aiCardState: AICardState.fromString(json['ai_card_state'] as String),
    generatedAt: json['generated_at'] as String,
  );
}

class MacroTargets {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;

  const MacroTargets({required this.calories, required this.proteinG, required this.carbsG, required this.fatsG});

  factory MacroTargets.fromJson(Map<String, dynamic> json) => MacroTargets(
    calories: json['calories'] as int,
    proteinG: json['protein_g'] as int,
    carbsG: json['carbs_g'] as int,
    fatsG: json['fats_g'] as int,
  );
}
```

**Note:** `home_models.dart` classes (`NextMealRecommendation`, `FlexPlanSlot`, `RecalibrationStatus`) need `fromJson` factories added.

---

### 1.4 `meal_log_response.dart`

**Change:** `updated_state` → `updated_plan`

```dart
class MealLogResponse {
  final Meal meal;
  final DailyPlan updatedPlan;  // was DashboardState updatedState

  const MealLogResponse({required this.meal, required this.updatedPlan});

  factory MealLogResponse.fromJson(Map<String, dynamic> json) =>
      MealLogResponse(
        meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
        updatedPlan: DailyPlan.fromJson(json['updated_plan'] as Map<String, dynamic>),
      );
}
```

**Note:** Decide whether `DailyPlan` is the same as `DashboardState` or a separate model. The contract uses the same shape. Recommend: **reuse `DashboardState` and rename it to `DailyPlan`** for clarity.

---

### 1.5 New: `history_response.dart`

```dart
class HistoryResponse {
  final List<DayHistoryEntry> days;

  const HistoryResponse({required this.days});

  factory HistoryResponse.fromJson(Map<String, dynamic> json) =>
      HistoryResponse(
        days: (json['days'] as List)
            .map((e) => DayHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DayHistoryEntry {
  final String dayId;
  final MacroTargets consumed;
  final MacroTargets targets;
  final int mealCount;
  final String aiSummary;

  const DayHistoryEntry({...});

  factory DayHistoryEntry.fromJson(Map<String, dynamic> json) =>
      DayHistoryEntry(
        dayId: json['day_id'] as String,
        consumed: MacroTargets.fromJson(json['consumed'] as Map<String, dynamic>),
        targets: MacroTargets.fromJson(json['targets'] as Map<String, dynamic>),
        mealCount: json['meal_count'] as int,
        aiSummary: json['ai_summary'] as String,
      );
}
```

---

### 1.6 New: `pantry_models.dart`

```dart
class PantryItemResponse {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final String? quantityHint;
  final bool isHighProtein;
  final String createdAt;
  final String updatedAt;

  factory PantryItemResponse.fromJson(Map<String, dynamic> json) => ...;
}

class PantryListResponse {
  final List<PantryItemResponse> items;
  factory PantryListResponse.fromJson(Map<String, dynamic> json) => ...;
}
```

---

### 1.7 New: `user_profile.dart`

```dart
class User {
  final String id;
  final String? email;
  final String createdAt;
  final String updatedAt;
  final UserProfile profile;
  final MacroTargets targets;

  factory User.fromJson(Map<String, dynamic> json) => ...;
}

class UserProfile {
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final String activityLevel;
  final String goal;
  final List<String> dietaryRestrictions;

  factory UserProfile.fromJson(Map<String, dynamic> json) => ...;
}
```

---

### 1.8 New: `recommendation_models.dart`

```dart
class SwapResponse {
  final NextMealRecommendation nextMeal;
  factory SwapResponse.fromJson(Map<String, dynamic> json) => ...;
}

class QuickActionResponse {
  final NextMealRecommendation nextMeal;
  factory QuickActionResponse.fromJson(Map<String, dynamic> json) => ...;
}
```

---

## Phase 2: Update `home_models.dart` with JSON Factories

File: `lib/shared/models/home_models.dart`

Add `fromJson` to all classes so `DashboardState` can parse them:

```dart
class NextMealRecommendation {
  // ... existing fields ...

  factory NextMealRecommendation.fromJson(Map<String, dynamic> json) =>
      NextMealRecommendation(
        name: json['name'] as String,
        whyItFits: json['why_it_fits'] as String,
        prepMinutes: json['prep_minutes'] as int,
        calories: json['calories'] as int,
        protein: json['protein_g'] as int,
        carbs: json['carbs_g'] as int,
        fats: json['fats_g'] as int,
        emoji: json['emoji'] as String,
      );
}

class FlexPlanSlot {
  // ... existing fields ...

  factory FlexPlanSlot.fromJson(Map<String, dynamic> json) =>
      FlexPlanSlot(
        label: json['label'] as String,
        hint: json['hint'] as String,
        icon: _iconFromKey(json['icon_key'] as String),
        isOpen: json['is_open'] as bool,
        isOptional: json['is_optional'] as bool,
        isDone: json['is_done'] as bool? ?? false,
      );

  static IconData _iconFromKey(String key) {
    switch (key) {
      case 'lunch': return Icons.lunch_dining_rounded;
      case 'snack': return Icons.cookie_rounded;
      case 'dinner': return Icons.dinner_dining_rounded;
      case 'late': return Icons.nightlight_round;
      default: return Icons.restaurant;
    }
  }
}

class RecalibrationStatus {
  // ... existing fields ...

  factory RecalibrationStatus.fromJson(Map<String, dynamic> json) =>
      RecalibrationStatus(
        mode: RecalibrationMode.values.firstWhere(
          (e) => e.name == (json['mode'] as String).replaceAll('_', ''),
        ),
        title: json['title'] as String,
        detail: json['detail'] as String,
      );
}
```

---

## Phase 3: Rewrite `ApiService`

File: `lib/core/di/providers.dart`

### 3.1 Fix Error Parser

```dart
ApiException parseApiError(DioException e) {
  final data = e.response?.data;
  // Backend wraps errors in {"error": {"code": "...", "message": "..."}}
  final errorObj = (data is Map<String, dynamic>) ? data['error'] as Map<String, dynamic>? : null;
  final code = errorObj?['code'] as String?;
  final serverMessage = errorObj?['message'] as String?;

  switch (code) {
    case 'unauthorized':
      return ApiException(code: 'unauthorized', message: serverMessage ?? 'Session expired. Please sign in again.');
    case 'user_not_found':
      return ApiException(code: 'user_not_found', message: serverMessage ?? 'User not found. Complete setup first.');
    case 'validation_error':
      return ApiException(code: 'validation_error', message: serverMessage ?? 'Invalid input. Please check your data.');
    case 'rate_limited':
      return ApiException(code: 'rate_limited', message: 'Too many requests. Please slow down.');
    case 'analysis_failed':
      return ApiException(code: 'analysis_failed', message: 'AI analysis unavailable. Try again later.');
    case 'internal_error':
      return ApiException(code: 'internal_error', message: 'Something went wrong. Please try again.');
    default:
      return ApiException(code: code ?? 'unknown', message: serverMessage ?? 'Something went wrong.');
  }
}
```

### 3.2 Update Existing Methods

```dart
Future<DailyPlan> fetchDashboard() async {
  final response = await _dio.get('/dashboard/state');
  return DailyPlan.fromJson(response.data);  // was DashboardState
}

Future<HistoryResponse> fetchHistory({int days = 7}) async {
  final response = await _dio.get('/history', queryParameters: {'days': days});
  return HistoryResponse.fromJson(response.data);  // was List<DashboardState>
}

Future<MealLogResponse> logText(String description, {String? context}) async {
  final response = await _dio.post('/log/text', data: {
    'description': description,
    if (context != null) 'context': context,
  });
  return MealLogResponse.fromJson(response.data);
}
```

### 3.3 Add Missing Methods

```dart
Future<MealLogResponse> logManual(ManualLogRequest request) async {
  final response = await _dio.post('/log/manual', data: request.toJson());
  return MealLogResponse.fromJson(response.data);
}

Future<SwapResponse> swapMeal(String currentMealName) async {
  final response = await _dio.post('/recommendations/swap', data: {
    'current_meal_name': currentMealName,
    'reason': 'user_swap',
  });
  return SwapResponse.fromJson(response.data);
}

Future<QuickActionResponse> quickAction(String action) async {
  final response = await _dio.post('/recommendations/quick-action', data: {
    'action': action,
  });
  return QuickActionResponse.fromJson(response.data);
}

Future<PantryListResponse> fetchPantry() async {
  final response = await _dio.get('/pantry');
  return PantryListResponse.fromJson(response.data);
}

Future<PantryItemResponse> addPantryItem(PantryCreateRequest request) async {
  final response = await _dio.post('/pantry', data: request.toJson());
  return PantryItemResponse.fromJson(response.data);
}

Future<PantryItemResponse> updatePantryItem(String id, PantryUpdateRequest request) async {
  final response = await _dio.put('/pantry/$id', data: request.toJson());
  return PantryItemResponse.fromJson(response.data);
}

Future<void> deletePantryItem(String id) async {
  await _dio.delete('/pantry/$id');
}

Future<DailyPlan> fetchPlan() async {
  final response = await _dio.get('/plan');
  return DailyPlan.fromJson(response.data);
}

Future<User> fetchProfile() async {
  final response = await _dio.get('/users/me');
  return User.fromJson(response.data);
}

Future<User> updateProfile(ProfilePatchRequest request) async {
  final response = await _dio.patch('/users/me', data: request.toJson());
  return User.fromJson(response.data);
}
```

### 3.4 Remove `scanMenu()`

Delete the `scanMenu` method and `MenuScanResponse` / `RecommendedDish` models (or keep for future but don't use).

---

## Phase 4: Wire Up Stores

### 4.1 `DashboardStore` — Replace mock with API calls

File: `lib/stores/dashboard_store.dart`

**Constructor:** Remove `_seedMockData()`. Call `refresh()` instead.

**`refresh()` method:**
```dart
@action
Future<void> refresh() async {
  isLoading = true;
  hasError = false;
  try {
    final plan = await apiService.fetchDashboard();
    _applyPlan(plan);
  } catch (e) {
    hasError = true;
    errorMessage = e is ApiException ? e.message : 'Failed to load dashboard';
  } finally {
    isLoading = false;
  }
}

void _applyPlan(DailyPlan plan) {
  consumedCalories = plan.consumed.calories;
  consumedProtein = plan.consumed.proteinG;
  consumedCarbs = plan.consumed.carbsG;
  consumedFats = plan.consumed.fatsG;
  targetCalories = plan.targets.calories;
  targetProtein = plan.targets.proteinG;
  targetCarbs = plan.targets.carbsG;
  targetFats = plan.targets.fatsG;
  todayMeals = ObservableList.of(plan.meals);
  aiCardText = plan.aiCardText;
  aiCardState = plan.aiCardState;
  dayStatus = plan.dayStatus;
  nextMeal = plan.nextMeal;
  recalibration = plan.recalibration;
  flexPlan = ObservableList.of(plan.flexPlan);
}
```

**`addMeal()` method:** Change to call API
```dart
@action
Future<void> addMeal(Meal meal) async {
  // If meal has no id, it's a manual log
  final response = await apiService.logManual(ManualLogRequest(
    foodName: meal.foodName,
    calories: meal.calories,
    proteinG: meal.proteinG,
    carbsG: meal.carbsG,
    fatsG: meal.fatsG,
    source: meal.source,
  ));
  _applyPlan(response.updatedPlan);
}
```

**`acceptNextMeal()` method:**
```dart
@action
Future<void> acceptNextMeal() async {
  final meal = nextMeal;
  if (meal == null) return;
  final response = await apiService.logManual(ManualLogRequest(
    foodName: meal.name,
    calories: meal.calories,
    proteinG: meal.protein,
    carbsG: meal.carbs,
    fatsG: meal.fats,
    source: 'recommendation',
  ));
  _applyPlan(response.updatedPlan);
}
```

**`swapNextMeal()` method:**
```dart
@action
Future<void> swapNextMeal() async {
  final current = nextMeal?.name ?? '';
  final response = await apiService.swapMeal(current);
  nextMeal = response.nextMeal;
}
```

**`fetchHistory()` method:**
```dart
@action
Future<List<DayHistoryEntry>> fetchHistory({int days = 7}) async {
  final response = await apiService.fetchHistory(days: days);
  return response.days;
}
```

**Remove `_seedMockData()`**, `_recomputeDayStatus()`, and all mock fallback logic.

---

### 4.2 `OnboardingStore` — Wire to API

File: `lib/stores/onboarding_store.dart`

**`calculatePlan()` method:** Replace fake delays with real API call

```dart
@action
Future<UserSetupResponse> calculatePlan() async {
  loadingProgress = 0.3;
  loadingStatus = 'Creating your profile...';

  final request = toApiRequest();
  final response = await apiService.setupUser(request);

  loadingProgress = 1.0;
  loadingStatus = 'Done!';
  return response;
}
```

**`toApiRequest()` fix:**
```dart
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
  );
}
```

---

## Phase 5: Remove Dead Code

### Files to delete:
- `lib/data/models/user_model.dart` (unused)
- `lib/data/models/meal_model.dart` (unused, conflicts with `Meal`)
- `lib/data/models/macro_model.dart` (unused, logic moved to backend)
- `lib/shared/models/recommended_dish.dart` (menu scan removed)

### In `DashboardStore`:
- Remove `_seedMockData()`
- Remove `_recomputeDayStatus()`
- Remove `fetchHistory()` mock implementation

---

## Phase 6: Add Authentication Flow

The backend requires `Authorization: Bearer <firebase_id_token>`.

### New: `AuthStore`
```dart
class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  @observable String? firebaseToken;

  @action
  void setToken(String token) {
    firebaseToken = token;
    apiService.setAuthToken(token);
  }
}
```

### Wire Firebase Auth:
1. Add `firebase_auth` package
2. On app start, check for existing Firebase user
3. If logged in, get ID token and call `authStore.setToken(token)`
4. If no user, show onboarding

---

## Phase 7: Testing Checklist

After migration, verify these flows:

| Flow | Steps | Expected |
|------|-------|----------|
| Onboarding | Fill form → submit | `POST /users/setup` returns 201, navigates to home |
| Dashboard load | App opens | `GET /dashboard/state` loads, shows AI card + next meal + flex plan |
| Vision log | Camera → take photo → confirm | `POST /log/vision`, dashboard updates with new meal + recalibrated plan |
| Text log | Text input → submit | `POST /log/text`, same update behavior |
| Accept recommendation | Tap "Eat this" | `POST /log/manual` (source: recommendation), meal logged |
| Swap | Tap "Swap" | `POST /recommendations/swap`, new meal shown |
| Quick action | Tap chip (e.g., "Need protein") | `POST /recommendations/quick-action`, biased meal shown |
| Pantry | View list → add item | `GET /pantry`, `POST /pantry` |
| History | View history tab | `GET /history?days=7`, shows daily summaries |
| Profile | View → edit weight | `PATCH /users/me`, targets recomputed |
| Day rollover | Open app on new day | Fresh plan with zeroed consumed |

---

## Estimated Effort

| Phase | Hours | Complexity |
|-------|-------|------------|
| 0: Constants update | 0.5 | Easy |
| 1: Model rewrites | 4-6 | Medium |
| 2: home_models JSON | 1-2 | Easy |
| 3: ApiService rewrite | 2-3 | Medium |
| 4: Store wiring | 4-6 | High |
| 5: Dead code removal | 1 | Easy |
| 6: Auth flow | 3-4 | Medium |
| 7: Testing & polish | 4-6 | Medium |
| **Total** | **~20-28 hours** | |

---

## Gotchas to Watch

1. **`Meal` field renames** — Every `meal.protein` call site must become `meal.proteinG`. Use IDE refactor (Rename Symbol).
2. **`FlexPlanSlot.icon`** — Backend sends `icon_key: String`, Flutter uses `IconData`. Need a mapping function.
3. **`DayStatus` enum** — Backend sends `snake_case`, Flutter enum names are `camelCase`. Parse carefully.
4. **Image URLs** — Backend returns presigned URLs (time-limited). Don't cache them indefinitely.
5. **Offline mode** — If you want offline support, add a local cache layer *after* the API integration is solid.
6. **Auth token refresh** — Firebase ID tokens expire after 1 hour. Implement automatic refresh before API calls.

---

## Immediate Next Step

Start with **Phase 1 (Models)**. The `Meal` and `DashboardState` rewrites are the foundation everything else depends on. Once those parse correctly, the store wiring becomes mechanical.
