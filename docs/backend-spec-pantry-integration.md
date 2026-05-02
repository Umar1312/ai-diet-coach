# Backend Integration Spec — Pantry-Aware Recommendations

**Date:** 2026-05-02
**Author:** Mobile Client Team
**Status:** Draft — Awaiting Backend Review

---

## 1. Objective

The app's core value proposition is: *"Stay on your diet without eating on a rigid schedule. The app adjusts your next meals in real time based on what you've eaten, what you have, and where your goals stand."*

The **"what you have"** pillar is currently under-delivered. Pantry exists as a standalone inventory, but recommendations do not demonstrably consider it. This spec defines the minimal API changes required to make the pantry an active input into the recommendation engine.

---

## 2. Guiding UX Principle

> **The AI should feel like it "just knows" what the user has.**

We do NOT want a rigid "only cook from pantry" mode. Instead:
- **The client automatically sends `prefer_pantry=true` on every recommendation request whenever the user's pantry is not empty.** There is no manual toggle — the AI always grounds suggestions in what the user has, unless their pantry is empty.
- When pantry items are used in a recommendation, the backend should **explicitly say so** in the response so the frontend can surface the reasoning.
- When the user logs a meal, they can tap pantry chips to tell the AI *"I'm using this item"* — improving future recommendations.

---

## 3. API Changes

### 3.1 `GET /dashboard/state`

**Current:** Returns the daily plan without pantry context.

**Change:** Accept an optional query parameter.

```
GET /dashboard/state?prefer_pantry=true
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prefer_pantry` | `boolean` (string `"true"` / `"false"`) | No | **Automatically sent by the client as `true` whenever the user's pantry is not empty.** When `true`, the recommendation engine should weight pantry items more heavily when selecting `next_meal`. When `false` or omitted, the engine may still use pantry items but should not prioritize them. |

**Response Changes:**

The `next_meal` object should include two new optional fields:

```json
{
  "next_meal": {
    "name": "Grilled chicken salad",
    "why_it_fits": "Light and high-protein to keep you on track for dinner.",
    "prep_minutes": 15,
    "calories": 420,
    "protein_g": 42,
    "carbs_g": 18,
    "fats_g": 12,
    "emoji": "🥗",
    "used_pantry_items": ["Chicken breast", "Mixed greens"],
    "pantry_reasoning": "Uses the chicken and greens you already have, so you don't need to shop."
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `used_pantry_items` | `string[]` | No | Names of pantry items that appear in this recommendation. Empty array or omitted if none. |
| `pantry_reasoning` | `string` | No | A human-readable sentence explaining why pantry items were chosen. Optional even if `used_pantry_items` is present. |

**Backend Behavior:**
- When `prefer_pantry=true`, the engine should **prioritize** meals that can be built from the user's pantry inventory.
- When `prefer_pantry=false` or omitted, the engine may still use pantry items if they happen to fit well, but should populate `used_pantry_items` and `pantry_reasoning` so the frontend can surface the connection.

---

### 3.2 `POST /recommendations/swap`

**Current:**
```json
POST /recommendations/swap
{
  "current_meal_name": "Grilled chicken salad",
  "reason": "user_swap"
}
```

**Change:** Accept two new optional body fields.

```json
POST /recommendations/swap
{
  "current_meal_name": "Grilled chicken salad",
  "reason": "user_swap",
  "prefer_pantry": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prefer_pantry` | `boolean` | No | **Automatically sent by the client as `true` whenever the user's pantry is not empty.** When `true`, the swapped recommendation should strongly favor pantry items. |
| `reason` | `string` | No | Previously hardcoded to `"user_swap"`. Now accepts freeform user reason (e.g., `"not_feeling_it"`, `"too_much_prep"`). |

**Response:** Same `SwapResponse` shape as today, but the returned `next_meal` may include `used_pantry_items` and `pantry_reasoning`.

---

### 3.3 `POST /recommendations/quick-action`

**Current:**
```json
POST /recommendations/quick-action
{
  "action": "im_hungry"
}
```

**Change:** Accept an optional `prefer_pantry` body field.

```json
POST /recommendations/quick-action
{
  "action": "im_hungry",
  "prefer_pantry": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `prefer_pantry` | `boolean` | No | **Automatically sent by the client as `true` whenever the user's pantry is not empty.** When `true`, the quick-action response should favor pantry-compatible meals. |

**Response:** Same `QuickActionResponse` shape, with optional `used_pantry_items` / `pantry_reasoning` on `next_meal`.

---

### 3.4 `POST /log/text`

**Current:**
```json
POST /log/text
{
  "description": "Two scrambled eggs with toast",
  "context": null
}
```

**Change:** Accept an optional `pantry_item_ids` body field.

```json
POST /log/text
{
  "description": "Two scrambled eggs with toast",
  "context": null,
  "pantry_item_ids": ["Egg", "Sourdough bread"]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pantry_item_ids` | `string[]` | No | Names (or IDs, depending on backend preference) of pantry items the user explicitly indicated they are using. The backend can use this to: 1) improve macro estimation accuracy, 2) mark items as "recently used" or deplete quantity hints, 3) improve future recommendations. |

> **Open Question:** Should `pantry_item_ids` contain database UUIDs or human-readable names? The client currently sends `name` strings because the pantry grid does not expose IDs to the UI layer. If the backend needs UUIDs, please specify and we will update the client to pass them through.

---

## 4. Data Model Changes

### `NextMealRecommendation` (in `DailyPlan.next_meal`)

```dart
class NextMealRecommendation {
  String name;
  String whyItFits;
  int prepMinutes;
  int calories;
  int proteinG;
  int carbsG;
  int fatsG;
  String emoji;
  List<String> usedPantryItems;  // NEW
  String? pantryReasoning;       // NEW
}
```

JSON keys:
- `used_pantry_items`
- `pantry_reasoning`

---

## 5. Backend Behavioral Requirements

### 5.1 Recommendation Engine

`prefer_pantry=true` is the **default active state** whenever the user has items in their pantry. The client sends it automatically; there is no manual toggle.

When `prefer_pantry=true` is received on any recommendation endpoint:

1. **Filter / score** candidate meals by pantry overlap. A meal that uses 2+ pantry items should rank higher than one that uses none.
2. **Do not hard-filter** to pantry-only unless the user's pantry is genuinely sufficient to build a balanced meal. If no good pantry match exists, fall back to a regular recommendation and simply omit `used_pantry_items`.
3. **Always populate `used_pantry_items` and `pantry_reasoning`** when pantry items are involved so the frontend can surface the connection. Good examples:
   - *"Uses the chicken breast and rice you already have."*
   - *"Built around your eggs and spinach to save a trip to the store."*
   - Bad example: *"This meal uses pantry items."* (too generic)

When `prefer_pantry=false` (user has an empty pantry), the engine should behave exactly as it does today, ignoring pantry data.

### 5.2 Macro Estimation (`/log/text`)

When `pantry_item_ids` is provided:

1. Use the known macros of the identified pantry items as anchors for AI estimation.
2. If the user says *"chicken salad"* and sends `["Chicken breast"]`, the calorie estimate should align with the known macros of that pantry item rather than a generic chicken salad.
3. Optionally mark those items as "recently used" so quantity hints like *"400g left"* can be updated.

---

## 6. Migration & Backward Compatibility

All new fields are **optional** in both request and response. The client already defensively handles missing keys:

```dart
usedPantryItems:
    (json['used_pantry_items'] as List?)
        ?.map((e) => e as String)
        .toList() ??
    const [],
pantryReasoning: json['pantry_reasoning'] as String?,
```

Older backend versions that do not return these fields will simply result in an empty pantry chip list and no pantry reasoning shown — graceful degradation.

---

## 7. Open Questions

1. **IDs vs. Names for `pantry_item_ids`:** Should the client send pantry item UUIDs or human-readable names? Currently sends names for simplicity.
2. **Quantity depletion:** Should logging with `pantry_item_ids` automatically reduce quantity hints (e.g., *"400g left"* → *"200g left"*)? If so, what depletion heuristic should the backend use?
3. **Pantry freshness scoring:** Should items added long ago be deprioritized in recommendations even when `prefer_pantry=true`?
4. **`/log/vision` and `/log/manual` parity:** Should image and manual logging also accept `pantry_item_ids`? The client can add this easily if needed.

---

## 8. Acceptance Criteria

- [ ] `GET /dashboard/state?prefer_pantry=true` returns recommendations that demonstrably use pantry items when possible.
- [ ] `POST /recommendations/swap` with `prefer_pantry: true` returns a different (pantry-weighted) meal than without it.
- [ ] `next_meal` includes `used_pantry_items` and `pantry_reasoning` when pantry items are involved.
- [ ] `POST /log/text` accepts `pantry_item_ids` and uses them for estimation.
- [ ] All changes are backward-compatible: omitting new fields produces pre-existing behavior.
