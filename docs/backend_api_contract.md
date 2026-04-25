# Backend API Contract — AI Diet Coach

> **Purpose:** Defines the exact data contracts and endpoints the Flutter client expects from the backend.
> **Scope:** Models, request/response shapes, status codes, and validation rules. No implementation details.

---

## 1. Authentication

Every request must include:

```
Authorization: Bearer <firebase_id_token>
```

The backend verifies the token and extracts the Firebase `uid` as `user_id`. If the user does not exist, return `404 user_not_found`.

---

## 2. Error Response

All errors return:

```json
{
  "error": {
    "code": "snake_case_string",
    "message": "human readable description",
    "details": {}
  }
}
```

| Code | HTTP | When |
|---|---|---|
| `unauthorized` | 401 | Missing or invalid token |
| `user_not_found` | 404 | Valid token, user not set up |
| `validation_error` | 422 | Missing/invalid field |
| `rate_limited` | 429 | Too many analysis requests |
| `analysis_failed` | 502 | Vision/text analysis unavailable |
| `internal_error` | 500 | Catch-all |

---

## 3. Models

### 3.1 User

```json
{
  "id": "string (firebase uid)",
  "email": "string | null",
  "created_at": "ISO8601",
  "updated_at": "ISO8601",
  "profile": {
    "gender": "male | female | other",
    "age": 28,
    "height_cm": 175,
    "weight_kg": 78,
    "target_weight_kg": 72,
    "activity_level": "sedentary | light | moderate | active | very_active",
    "goal": "lose_weight | maintain | gain_muscle",
    "dietary_restrictions": ["vegetarian", "gluten_free"]
  },
  "targets": {
    "calories": 2191,
    "protein_g": 170,
    "carbs_g": 240,
    "fats_g": 60
  }
}
```

---

### 3.2 Meal

```json
{
  "id": "uuid",
  "user_id": "string",
  "food_name": "Grilled chicken & rice bowl",
  "calories": 560,
  "protein_g": 48,
  "carbs_g": 62,
  "fats_g": 14,
  "image_url": "string | null",
  "logged_at": "ISO8601",
  "source": "vision | text | voice | barcode | recommendation",
  "day_id": "string (YYYY-MM-DD)"
}
```

---

### 3.3 PantryItem

```json
{
  "id": "uuid",
  "user_id": "string",
  "name": "Chicken breast",
  "emoji": "🍗",
  "quantity_hint": "400g",
  "is_high_protein": true,
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

---

### 3.4 DailyPlan

Returned by `GET /dashboard/state`. This is the primary compound object powering the home screen.

```json
{
  "day_id": "2026-04-24",
  "user_id": "string",
  "targets": {
    "calories": 2191,
    "protein_g": 170,
    "carbs_g": 240,
    "fats_g": 60
  },
  "consumed": {
    "calories": 620,
    "protein_g": 42,
    "carbs_g": 78,
    "fats_g": 18
  },
  "meals": [ /* Meal[] */ ],
  "flex_plan": [
    {
      "slot": "lunch",
      "label": "Lunch",
      "hint": "High-protein, ~560 cal",
      "icon_key": "lunch",
      "is_open": true,
      "is_optional": false
    }
  ],
  "next_meal": {
    "name": "Grilled chicken & rice bowl",
    "why_it_fits": "Closes your protein gap, leaves room for a relaxed dinner.",
    "prep_minutes": 15,
    "calories": 560,
    "protein_g": 48,
    "carbs_g": 62,
    "fats_g": 14,
    "emoji": "🍗"
  },
  "recalibration": {
    "mode": "balanced | lighter_dinner | need_protein | day_adjusted",
    "title": "You still need 128g protein today",
    "detail": "I shifted tonight toward a protein-heavy plate so dessert still fits."
  },
  "day_status": "on_track | slightly_over | need_protein | room_for_dinner | goal_hit",
  "ai_card_text": "You're behind on protein. A high-protein lunch will close the gap.",
  "ai_card_state": "on_track | skipped_meal | behind_protein | calorie_limit | goal_hit",
  "generated_at": "ISO8601"
}
```

**Constraints:**
- One `DailyPlan` per user per calendar day (`day_id`).
- `generated_at` must update on every recalculation.
- `next_meal` must be pantry-aware when the user's pantry is non-empty.
- `recalibration` must describe what changed since the previous state.

---

### 3.5 DayHistory

```json
{
  "day_id": "2026-04-23",
  "consumed": { "calories": 2180, "protein_g": 168, "carbs_g": 235, "fats_g": 59 },
  "targets": { "calories": 2191, "protein_g": 170, "carbs_g": 240, "fats_g": 60 },
  "meal_count": 3,
  "ai_summary": "Almost perfect. Great job yesterday."
}
```

---

## 4. Endpoints

### 4.1 Onboarding

#### `POST /users/setup`

Creates or updates the user's profile and computes targets.

**Request:**
```json
{
  "gender": "male",
  "age": 28,
  "height_cm": 175,
  "weight_kg": 78,
  "target_weight_kg": 72,
  "activity_level": "moderate",
  "goal": "lose_weight",
  "dietary_restrictions": ["gluten_free"]
}
```

**Response:** `201 Created`
```json
{
  "user": { /* User object */ },
  "plan": { /* DailyPlan for today */ }
}
```

**Validation rules:**
- `age`: 13–120
- `height_cm`: 50–300
- `weight_kg`: 20–300
- `activity_level`: one of the enum values
- `goal`: one of the enum values

---

### 4.2 Dashboard

#### `GET /dashboard/state`

Returns the full state needed to render the home screen.

**Response:** `200 OK` → `DailyPlan` object

**Failure behavior:** If recommendation generation fails, still return `DailyPlan` with a fallback `next_meal` (e.g., a generic safe option). Never return 500 for the home screen.

---

### 4.3 Meal Logging

All three endpoints return the same compound shape: the created meal plus the recalculated plan.

**Common response:** `200 OK`
```json
{
  "meal": { /* Meal object */ },
  "updated_plan": { /* DailyPlan */ }
}
```

---

#### `POST /log/vision`

**Request:** `multipart/form-data`
- `image`: JPG/PNG file (required)
- `context`: `"lunch" | "dinner" | "snack"` (optional)

---

#### `POST /log/text`

**Request body:**
```json
{
  "description": "Large chicken burrito with sour cream and guac",
  "context": "lunch"
}
```

**Validation:** `description` required, min 2 chars.

---

#### `POST /log/manual`

Called when the user accepts a recommendation ("Eat this") or enters macros manually.

**Request body:**
```json
{
  "food_name": "Grilled chicken & rice bowl",
  "calories": 560,
  "protein_g": 48,
  "carbs_g": 62,
  "fats_g": 14,
  "source": "recommendation"
}
```

**Validation:**
- `food_name`: required, max 200 chars
- `calories`: 0–5000
- `protein_g`, `carbs_g`, `fats_g`: 0–500 each
- `source`: one of the enum values

---

### 4.4 Recommendations

#### `POST /recommendations/swap`

User tapped "Swap" on the current recommendation. Returns an alternative without logging anything.

**Request body:**
```json
{
  "current_meal_name": "Grilled chicken & rice bowl",
  "reason": "user_swap"
}
```

**Response:** `200 OK`
```json
{
  "next_meal": {
    "name": "Salmon poke bowl",
    "why_it_fits": "High-quality protein + omega-3s. Fits your budget.",
    "prep_minutes": 10,
    "calories": 540,
    "protein_g": 42,
    "carbs_g": 58,
    "fats_g": 16,
    "emoji": "🍣"
  }
}
```

**Constraint:** The returned meal must differ from `current_meal_name` and still respect the user's remaining macro budget, dietary restrictions, and pantry.

---

#### `POST /recommendations/quick-action`

User tapped a quick-action chip.

**Request body:**
```json
{
  "action": "need_protein | hungry | no_cooking | ate_too_much | something_sweet"
}
```

**Response:** `200 OK` → `{ "next_meal": { ... } }`

**Constraint:** The recommendation must be biased by the action type but still respect macro budget and pantry.

---

### 4.5 Pantry

#### `GET /pantry`

**Response:** `200 OK`
```json
{
  "items": [ /* PantryItem[] */ ]
}
```

---

#### `POST /pantry`

**Request body:**
```json
{
  "name": "Chicken breast",
  "emoji": "🍗",
  "quantity_hint": "400g",
  "is_high_protein": true
}
```

**Validation:** `name` required, max 100 chars.

**Response:** `201 Created` → created `PantryItem`

---

#### `PUT /pantry/:id`

**Request body:** partial `PantryItem` (any subset of fields)

**Response:** `200 OK` → updated `PantryItem`

---

#### `DELETE /pantry/:id`

**Response:** `204 No Content`

---

### 4.6 Plan

#### `GET /plan`

Returns the daily plan scoped to the Plan tab.

**Response:** `200 OK`
```json
{
  "day_id": "2026-04-24",
  "targets": { "calories": 2191, "protein_g": 170, "carbs_g": 240, "fats_g": 60 },
  "consumed": { "calories": 620, "protein_g": 42, "carbs_g": 78, "fats_g": 18 },
  "flex_plan": [ /* FlexPlanSlot[] */ ],
  "meals": [ /* Meal[] */ ]
}
```

---

### 4.7 History

#### `GET /history?days=7`

Returns recent daily summaries.

**Query params:**
- `days`: int, 1–30, default 7

**Response:** `200 OK`
```json
{
  "days": [
    {
      "day_id": "2026-04-24",
      "consumed": { "calories": 620, "protein_g": 42, "carbs_g": 78, "fats_g": 18 },
      "targets": { "calories": 2191, "protein_g": 170, "carbs_g": 240, "fats_g": 60 },
      "meal_count": 2,
      "ai_summary": "You're behind on protein."
    }
  ]
}
```

**Constraint:** Returns the most recent `N` days that have data, up to `days` limit. Days with zero meals may be omitted.

---

### 4.8 Profile

#### `GET /users/me`

**Response:** `200 OK` → `User` object

---

#### `PATCH /users/me`

**Request body:** partial `User.profile` (any subset of fields)

**Response:** `200 OK` → updated `User`

**Behavior:** If any field that affects target calculation changes (`weight_kg`, `height_cm`, `age`, `activity_level`, `goal`), the backend must recompute `targets` and return the updated values.

---

## 5. Contract Rules

### 5.1 Compound Write Responses

After any meal log, the backend must return the new `DailyPlan` so the client updates in a single round-trip.

| Endpoint | Must return |
|---|---|
| `POST /log/vision` | `{ meal, updated_plan }` |
| `POST /log/text` | `{ meal, updated_plan }` |
| `POST /log/manual` | `{ meal, updated_plan }` |
| `POST /recommendations/swap` | `{ next_meal }` |
| `POST /recommendations/quick-action` | `{ next_meal }` |

### 5.2 DailyPlan Constraints

- `day_id` format: `YYYY-MM-DD` in UTC.
- `next_meal.calories` must not exceed `targets.calories - consumed.calories` by more than 10%.
- `flex_plan` must contain exactly 4 slots: `lunch`, `snack`, `dinner`, `late`.
- `recalibration` must describe a delta. If state is unchanged, still return current state.

### 5.3 Fallback Behavior

If the recommendation engine cannot generate a personalized meal, return a generic safe fallback:

```json
{
  "name": "Balanced chicken salad",
  "why_it_fits": "A safe default that fits most plans.",
  "prep_minutes": 10,
  "calories": 500,
  "protein_g": 35,
  "carbs_g": 45,
  "fats_g": 15,
  "emoji": "🥗"
}
```

The `GET /dashboard/state` endpoint must never fail because recommendations are unavailable.

### 5.4 Day Rollover

On the first request for a new calendar day where no `DailyPlan` exists:
- Create a new plan with `consumed = { all zeros }`.
- Copy `targets` from the user's profile.
- Set `day_status = on_track` and `recalibration.mode = day_adjusted`.
- Generate a fresh `next_meal` based on time of day.

---

## 6. Appendix: Mock → Real Endpoint Mapping

| Flutter Mock | Backend Endpoint |
|---|---|
| `DashboardStore._seedMockData()` | `GET /dashboard/state` |
| `dashboardStore.addMeal()` | `POST /log/manual` |
| `dashboardStore.acceptNextMeal()` | `POST /log/manual` (source: recommendation) |
| `dashboardStore.swapNextMeal()` | `POST /recommendations/swap` |
| Quick action chips | `POST /recommendations/quick-action` |
| Pantry list | `GET /pantry` |
| Plan screen | `GET /plan` |
| History screen | `GET /history?days=7` |
| Profile screen | `GET /users/me` + `PATCH /users/me` |
