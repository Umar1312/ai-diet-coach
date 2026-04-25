# AI Diet Buddy — Agent Instructions

## API Integration Protocol

Whenever asked to integrate a new API endpoint, **always** dispatch a subagent to the backend codebase at `/Users/umarsalim/Developer/api_service_diet_coach_ai` to research the full API contract. The subagent must return:

- **HTTP method** (GET, POST, PUT, DELETE, etc.)
- **Endpoint path** and any path parameters
- **Request body schema** (field names, types, required vs optional, validation rules)
- **Response body schema** (success and error shapes, status codes)
- **Authentication requirements** (headers, tokens, etc.)
- **Example request/response payloads**

Use the returned contract data to build the correct Dart models, API service methods, and store logic in the Flutter app. Do NOT guess or assume the contract — always verify against the backend source code first.

## Project Overview

AI Diet Buddy is a Flutter mobile app that acts as a personal AI nutrition coach. Users log meals via text description, camera photo, or manual entry. The AI estimates macros and provides daily recommendations to help users hit their calorie and protein goals. The app features a dashboard with macro ring visualizations, meal recommendations, pantry management, and meal history.

## Tech Stack

- **Framework**: Flutter 3.11.4+, Dart 3
- **State Management**: MobX (manual — no codegen for new stores)
- **Navigation**: go_router with StatefulShellRoute for persistent tabs
- **HTTP Client**: Dio
- **Auth**: Firebase Auth (planned, currently dev-token bypass)
- **Charts**: Custom CustomPainter rings (no fl_chart in main UI)
- **Fonts**: Google Fonts (Open Sans)

## Architecture

### Project Structure

```
lib/
├── main.dart                    # Global singleton stores, app bootstrap
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      # All colors
│   │   ├── app_constants.dart   # Config, API URLs, enums
│   │   └── app_theme.dart       # Material theme with Open Sans
│   ├── di/
│   │   └── providers.dart       # Dio + ApiService singleton
│   └── router/
│       └── app_router.dart      # go_router configuration
├── features/
│   └── log_meal/
│       ├── stores/              # Feature-specific MobX stores
│       ├── text_log_screen.dart
│       ├── camera_screen.dart
│       └── meal_confirm_sheet.dart
├── presentation/
│   ├── screens/                 # Page-level widgets
│   │   ├── dashboard/
│   │   ├── home/
│   │   ├── onboarding/
│   │   ├── pantry/
│   │   ├── plan/
│   │   ├── profile/
│   │   └── history/
│   └── widgets/                 # Shared UI widgets
├── shared/
│   ├── models/                  # Data models with fromJson/toJson
│   └── widgets/                 # Shared utility widgets
└── stores/
    ├── auth_store.dart          # Uses codegen (legacy)
    ├── onboarding_store.dart    # Uses codegen (legacy)
    ├── dashboard_store.dart     # Manual MobX (preferred)
    └── auth_store.g.dart        # Generated — do not edit
```

### State Management — MobX WITHOUT Codegen

**Rule**: All new stores MUST use manual MobX (like `DashboardStore`). Do NOT use `mobx_codegen` for new stores.

**Pattern**:
```dart
import 'package:mobx/mobx.dart';

class MyStore {
  // Observables
  final fieldName = Observable<String>('');
  final isLoading = Observable<bool>(false);

  // Computed
  late final canSubmit = Computed<bool>(
    () => fieldName.value.trim().isNotEmpty && !isLoading.value,
  );

  // Actions
  void setField(String value) {
    runInAction(() {
      fieldName.value = value;
    });
  }

  Future<void> submit() async {
    runInAction(() => isLoading.value = true);
    try {
      // API call
    } finally {
      runInAction(() => isLoading.value = false);
    }
  }
}
```

**Global Stores** (singletons in `main.dart`):
```dart
final authStore = AuthStore();
final onboardingStore = OnboardingStore();
final dashboardStore = DashboardStore();
final textLogStore = TextLogStore();
```

**In UI**, wrap reactive widgets with `Observer`:
```dart
Observer(builder: (_) {
  return Text(store.fieldName.value);
});
```

## Design Language

### CalAI-Style Dashboard (Current)

The app follows an extreme minimalism design language inspired by CalAI:

- **Massive typography** for hero numbers
- **Only what matters** — no clutter, no gradients on text
- **Generous whitespace** (28px horizontal padding standard)
- **Rounded everything** (16px–32px border radius)
- **Subtle surfaces** (light gray cards on white background)

### Colors (`AppColors`)

```dart
// Backgrounds
AppColors.background      // White #FFFFFF
AppColors.surface         // Light gray #F0F0F0
AppColors.surface2        // Slightly darker #ECE8E8

// Text
AppColors.textPrimary     // Near black #1E1A24
AppColors.textSecondary   // Gray #6E6E80
AppColors.textTertiary    // Light gray #A1A1B0
AppColors.textOnPrimary   // White #FFFFFF

// Macro Rings
AppColors.calories        // Red #DE6969
AppColors.protein         // Green #64993A
AppColors.carbs           // Orange #DE9A69
AppColors.fats            // Blue #6998DE

// UI
AppColors.primary         // Black #000000
AppColors.border          // #E5E5EA
AppColors.success         // Green #64993A
AppColors.error           // Red #DE6969
AppColors.warning         // Black #000000
```

### Typography

Primary font: **Open Sans** via Google Fonts

| Role | Size | Weight | Letter Spacing | Height |
|---|---|---|---|---|
| Hero title | 32–36px | w800 | -1.0 to -1.2 | 1.1 |
| Section title | 20px | w700 | -0.5 | 1.2 |
| Body | 16px | w500 | — | 1.4 |
| Caption | 14px | w500–w600 | — | 1.4 |
| Button | 17–18px | w700 | -0.3 | — |

### Spacing

- Screen horizontal padding: **28px** (not 16 or 24)
- Section gaps: **32–48px**
- Card padding: **24–28px**
- Card border radius: **20–32px**
- Button height: **56–64px**
- Button border radius: **16–20px**

### Buttons

**Primary CTA**:
- Full width, height 64
- Background: `AppColors.textPrimary` (black)
- Foreground: `AppColors.textOnPrimary` (white)
- Border radius: 20
- Elevation: 0
- Text: 18px, w700, letterSpacing -0.3
- Disabled state: `AppColors.border` bg, `AppColors.textTertiary` fg

**Loading state**: White `CircularProgressIndicator` centered in button, strokeWidth 2.5

**Secondary / Text button**: Transparent bg, `AppColors.textSecondary` text, 16px w600

**Icon buttons**: 48×48 circle, `AppColors.surface` background, `AppColors.textPrimary` icon, size 22

### Cards

- Background: `AppColors.surface` or `AppColors.background`
- Border radius: 20–32
- Border: optional 0.5px `AppColors.border`
- Elevation: 0 (flat design)
- No shadows in main UI

### Input Fields

- Background: `AppColors.surface`
- Border radius: 20
- No border, no outline
- Content padding: 20px
- Text: 17px, w500, `AppColors.textPrimary`
- Hint: 17px, w400, `AppColors.textTertiary`

### Error States

Error banner (not toast):
- Background: `AppColors.error.withValues(alpha: 0.08)`
- Border radius: 16
- Icon: `Icons.error_outline`, `AppColors.error`, size 20
- Text: 14px, w600, `AppColors.error`
- Padding: 16px

### Success Feedback

Floating SnackBar:
- Behavior: `SnackBarBehavior.floating`
- Margin: `EdgeInsets.fromLTRB(24, 0, 24, 24)`
- Background: `AppColors.textPrimary` (black)
- Content: Green checkmark icon + "Logged!" text
- Shape: borderRadius 16
- Duration: 2 seconds

## Navigation

- **Router**: go_router with `StatefulShellRoute.indexedStack` for 4-tab bottom nav
- **Tabs**: Home, Pantry, Plan, Profile
- **Push on top** (outside shell): Camera, Text Log, History, Onboarding
- **Bottom nav**: Custom implementation (not Cupertino/Material)
  - Height: 64
  - Border top: 0.5px `AppColors.border`
  - Active: `AppColors.primary`, w600
  - Inactive: `AppColors.textTertiary`, w500
  - Icon size: 22
  - Label size: 11

## API Layer

All API calls go through `apiService` (singleton in `providers.dart`).

**Error handling**: Catch `ApiException` for user-facing messages, generic catch for fallback.

**Pattern**:
```dart
try {
  final response = await apiService.someEndpoint();
  dashboardStore.applyPlan(response.updatedPlan);
} on ApiException catch (e) {
  // Use e.message for user display
} catch (e) {
  // Generic fallback
}
```

## Widget Conventions

### Private widgets
Use `StatelessWidget` for UI pieces inside a screen file. Prefix with underscore:
```dart
class _CloseButton extends StatelessWidget { ... }
class _TextInput extends StatelessWidget { ... }
```

### Haptics
Always add haptic feedback on meaningful interactions:
```dart
HapticFeedback.mediumImpact();   // Primary actions (submit, log)
HapticFeedback.selectionClick(); // Secondary actions (chips, toggles)
```

### Screen structure
```dart
Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(...),
    ),
  ),
);
```

### No AppBar
Prefer custom header widgets over `AppBar` in new screens. If needed, `AppBar` should have:
- `backgroundColor: AppColors.background`
- `elevation: 0`
- `centerTitle: true`

## Models

- All models have `fromJson` factory constructor
- All models have `toJson` method
- Use `Map<String, dynamic>` for JSON
- Enum parsing: static `fromString` method with `orElse` fallback

## Feature Development Checklist

When adding a new feature:

1. [ ] Create feature folder under `lib/features/<feature_name>/`
2. [ ] Create manual MobX store in `stores/<feature>_store.dart`
3. [ ] Register store as global singleton in `main.dart`
4. [ ] Use `Observer` widgets for reactive UI
5. [ ] Follow 28px horizontal padding
6. [ ] Use `AppColors.surface` for input/card backgrounds
7. [ ] Black CTA buttons (64px height, borderRadius 20)
8. [ ] Add haptic feedback on actions
9. [ ] Handle `ApiException` for API errors
10. [ ] Show success snackbar on completion
11. [ ] Run `flutter analyze` before finishing

## Important Notes

- **Do NOT use `setState`** for business logic — always use MobX stores
- **Do NOT create new codegen stores** — manual MobX only
- **Do NOT use Material default padding** — 28px is the standard
- **Do NOT add drop shadows** — flat design language
- **Do NOT use gradient text** — solid colors only
- **Prefer `GestureDetector` over `InkWell`** for custom tap targets
- **Always dispose controllers** in `dispose()`
- **Always check `mounted`** before calling `context.go()` after async operations
