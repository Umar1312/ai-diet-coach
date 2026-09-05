# Adaptive planning implementation plan

Status: proposed implementation plan, 5 September 2026. No application changes made.

## Outcome and scope

Deliver this complete journey: log what actually happened, identify whether it replaced a planned meal, receive a practical adjustment using familiar available food, review it, and apply it without changing meals the user wants to preserve.

Update backend and Flutter contracts together. No migrations, legacy parsers, dual APIs, or backward-compatibility branches. Existing user-facing capabilities remain supported unless explicitly improved below. Do not delete existing data as part of this work; any development-data reset is a separate operation.

Repositories:

- Flutter: `/Users/umarsalim/Developer/Mobile/diet_coach_ai`
- Backend: `/Users/umarsalim/Developer/api_service_diet_coach_ai`

## Non-negotiable behavior

1. Logging succeeds independently of AI availability. Recommendation failure never means the meal was not saved.
2. A meal log, consumed totals and its slot linkage cannot partially commit or double-count on retry.
3. Viewing, dismissing or requesting another proposal never changes committed meals.
4. Proposal acceptance is atomic and rejects stale proposals.
5. Automatic changes preserve logged, skipped and protected meals. Explicit user edits can change a protected meal after the UI makes that intent clear.
6. All generation paths use the same profile, dietary restrictions, availability and time constraints.
7. Nutrition totals derive from the same portion data displayed to the user. AI output is a candidate, not trusted application state.
8. Failure, no change needed and no feasible recommendation are distinct outcomes.
9. Previewing recommendations does not count as eating them or consume an adaptation allowance.
10. Day identity uses the user's timezone, and actions target an explicit day rather than silently moving to a new day at midnight.

## Phase 0 — Baseline and contract design

Capture current backend and Flutter test results before editing. The audit ran 13 focused Flutter tests successfully; analysis reported an unused `_navBottomMargin` field. This is not a full baseline. Preserve unrelated working-tree changes.

Inventory callers for logging, editing/deleting logs, day generation, customization, swaps, proposal actions, onboarding, notifications and subscription gates. Record intentional behavior changes so tests preserve useful behavior rather than existing bugs.

Before integrating new endpoints, dispatch the required backend-contract subagent under AGENTS.md. Obtain method/path, authentication, required and optional fields, validation, success/error schemas, status codes and examples from actual backend source. Proposed contracts below are design decisions, not claims that endpoints already exist.

Deliver an updated OpenAPI contract and shared JSON fixtures for representative requests and responses. Test Dart parsing against those fixtures. Use typed error codes for stale state, invalid slot, unavailable recommendation and access exhaustion.

Exit: every affected caller and contract is mapped; baseline failures are documented; agreed schemas cover all phases.

## Phase 1 — One authoritative model and mutation path

### Domain models

- `DailyPlan`: stable day ID, revision, committed slots, optional pending proposal and explicit adaptation status.
- `PlannedMeal`: stable ID separate from display order, slot, lifecycle status, meal details and independent `is_protected` flag. Keep planned food distinct from actual logged food; link actuals through log IDs.
- `MealLog`: stable ID, operation ID, explicit day, consumed meal snapshot, source, intent (`planned`, `replacement`, `extra`) and optional slot ID. Validate which fields each intent requires. Notification is a source, not a meal intent.
- `Meal`: structured serving amount/unit, nutrition basis, components/ingredients, preparation minutes, cuisine and optional preparation steps. Permit fractional servings. Distinguish prepared-food components from recipe ingredients to prevent double-counting nutrition.
- `PlanProposal`: ID, source plan revision, generation context version, changed-slot patches, reason and trigger. Do not store a second full day whose logged slots can overwrite reality.
- `PlanningContext`: profile restrictions/preferences, pantry availability, time limits, committed meals, actual intake and protected slots. Version profile/pantry inputs or revalidate them before acceptance.

Use shared conversion functions from validated AI output to domain objects. Eliminate the current conversion that drops serving and ingredient information. Keep backend models authoritative; Flutter models represent the contract without reimplementing planning rules.

### Persistence and service boundaries

Create one application-level mutation service for log/create/edit/delete, slot changes and proposal acceptance. Routers validate transport input and call services; repositories handle persistence; pure functions calculate totals and eligibility.

Use optimistic concurrency with atomic revision checks at persistence, not an in-memory check followed by unrestricted save. Enforce unique user/day and operation identities. Idempotency keys persist across retries of the same action; a new user action gets a new key.

Commit log, totals, slot linkage and proposal invalidation together. Verify deployment support for database transactions before implementation. If unavailable, choose a single-document atomic aggregate for that state; do not simulate a transaction with consecutive writes and hope recovery works. Resolve this choice in Phase 0.

Keep AI/network calls outside transactions. Commit the log first, then request an adaptation against the resulting revision. If newer state wins while AI runs, discard stale output and return current state; do not auto-retry a non-idempotent mutation.

In Flutter, consolidate plan application in the existing dashboard/day-plan store instead of creating another writable plan copy. New feature stores use injected services and manual MobX. Move touched async business state out of widget `setState`. Use request versions for read races and operation IDs for writes.

Exit: concurrency tests demonstrate no duplicate logs, lost totals, stale commits or partial log state.

## Phase 2 — Correct logging and recoverable adaptation

### Logging UX

From a meal card or notification, carry its slot into logging. General logging presents an editable meal choice plus “Something extra.” Selecting a search result opens a small portion review; familiar planned meals retain one-tap confirmation. AI estimates require confirmation before saving and identify values as estimates.

Replacement completes the selected slot with actual intake and evaluates remaining meals. Extra adds intake without completing a slot. Planned confirmation still evaluates the resulting day when portions changed; do not infer “no adjustment” solely from the presence of a slot.

Wire edit and undo through the same mutation service. Deleting the linked log reopens that slot with its planned food and protection preserved; deleting an extra leaves slots unchanged. Editing updates totals and invalidates stale recommendations. Define and test repeated delete/retry behavior.

Separate “Saving meal” from “Checking remaining meals.” If adaptation fails after saving, show “Meal saved; update unavailable” with an adaptation-only retry. Never ask the user to relog it.

### Proposal lifecycle

Use separate explicit accept, dismiss and regenerate operations. Regenerate excludes rejected candidates and returns another pending proposal; retain the old proposal until a valid replacement is ready. Acceptance patches eligible slots only and validates proposal ID/revision/context. Stale acceptance returns a conflict and offers refreshed review.

Invalidate proposals after log corrections, slot mutations, new logs and relevant preference changes. A dismissed proposal stays dismissed until a meaningful new trigger. Provide a home entry to review a pending proposal after navigating away or restarting.

Route all adaptation entry points through the same pipeline: off-plan logging, edit/delete, skip, swap-and-rebalance and full regeneration. Explicit single-meal replacement may commit that selected meal, but any additional changes require review. Make this distinction clear in button labels.

Exit: replacement lunch completes lunch; extras do not; “Try another” and failure leave committed meals untouched; restart and concurrent actions preserve correct state.

## Phase 3 — Practical recommendation policy

Build one context builder for day generation, replanning and alternatives. Supply actual portions/macros for remaining meals, not just their names. Add maximum preparation time and protected slots. Preserve country/cuisine and restrictions in every path.

Use a deterministic assessment before calling AI: compare actual intake plus committed remaining meals with configured target tolerances. Tolerances are centrally defined product rules to evaluate with fixtures, not scattered magic numbers or clinical claims. A small extra that leaves the plan suitable should return `not_needed`.

Prefer preserving meals, then feasible portion changes, then dish substitutions. Validate generated candidates for slot identity, positive realistic portions, ingredient restrictions, preparation limit, protected meals, nutrition consistency and pantry claims. Apply a bounded correction attempt; if still invalid, return unavailable/no-feasible-change and keep the original plan. Remove invented salad/chicken fallback recommendations.

Restrictions are hard constraints; cuisine and pantry preference are ranking preferences unless the user selects “Use only what I have.” Unknown ingredient/restriction compatibility must not be presented as verified. A calorie target already exceeded must not produce zero-calorie dinners or forced compensatory restriction.

Represent pantry entries as staple identity plus availability (`available`, `unavailable`, `unknown`), without precise stock depletion. Show “You have” versus “Also needed”; unknown availability is not confirmed stock. “Don't have this” updates availability and asks for another candidate. No automatic deletion after eating.

Add “Keep this meal” to plan cards and “15 / 30 minutes” choices to quicker alternatives. Enforce constraints in both candidate validation and acceptance.

Exit: fixtures cover regional diets, missing ingredients, short cooking time, protected dinner, small snack, over-target intake and invalid AI output. Run a bounded real-generation evaluation for quality and latency; mocked tests alone cannot establish usable food suggestions.

## Phase 4 — Show the value with fewer steps

Enable the existing skipped pantry-onboarding decision and persisted stage transition. Do not bypass onboarding state by only navigating. Keep starter-chip selection and allow a small pantry to be useful.

Make home lead with one next-meal card: dish, household portion, preparation time, pantry match, short explanation, “Ate this” and “Change.” Keep macro totals and full-day access. Derive the next meal consistently from day state; do not maintain competing recommendations in separate stores.

Reuse meal detail and comparison widgets across home, plan, swaps and impact. Show portions in before/after changes. Keep explicit preserve/apply controls and the existing calm language. Prevent “No changes needed” from appearing on failed generation.

Handle foreground refresh and day rollover, resumed notification links, loading/error states and compact displays. Preserve history, custom plans, profile editing, authentication, subscription restore and navigation tabs.

Exit: complete the lunch-replacement journey on a device, including correction, protected dinner, pantry shortage and application restart, without unexplained state changes.

## Phase 5 — Paid validation and measurement

Add one server-owned adaptation-access policy shared by every premium adaptation entry point. Start with a configurable allowance of three successfully accepted adaptations; Pro retains unlimited access under the existing product policy. Preview, regeneration, errors, conflicts and retries do not consume credits. A later undo does not replenish a consumed credit. Atomic acceptance and credit consumption prevent double charging.

Expose access/remaining allowance to Flutter. Offer the paywall when a free user attempts acceptance after exhaustion; preserve their valid proposal across purchase and recheck freshness afterward. Keep store billing trials distinct from this product allowance. Preserve purchase restore, cancellation and entitlement-refresh behavior.

Record structured events for proposal displayed, accepted/dismissed, suggested meal logged, correction, generation failure, paywall shown and purchase/renewal. Use stable proposal/meal lineage so accepting a proposal is not mistaken for eating it. Deduplicate authoritative server events. Collect optional rejection reason without blocking navigation. Avoid raw food descriptions and sensitive profile data in analytics.

Exit: sandbox purchase, restore, expired entitlement, failed acceptance and concurrent acceptance all behave correctly; events reconstruct the value funnel without duplicates.

## Regression matrix and release gates

| Scenario | Required result |
|---|---|
| Planned meal / notification confirmation | One log; correct day/slot; totals correct |
| Different lunch | Lunch completed; only eligible remaining meals considered |
| Extra snack | No slot completed; small change can require no proposal |
| Edit / undo / retry | Correct totals/linkage; no duplicate write; proposal invalidated |
| Prepared dinner | Protection survives all automatic generation paths |
| Vegetarian/regional profile | Constraints survive initial plan, adaptation and swaps |
| Missing pantry food / time limit | Honest availability and valid preparation constraint |
| Accept / dismiss / try another | Only acceptance commits proposed changes |
| Two logs during generation | Older result cannot overwrite newer state |
| AI timeout or malformed output | Log remains saved; plan preserved; retry is safe |
| Day rollover / restart | Correct day; no stale notification mutation or lost proposal |
| Custom plan / skip / swap | Existing actions work through shared invariants |
| Pantry skip / resume onboarding | Correct persisted stage and usable initial plan |
| Free allowance / Pro / restore | Server-authoritative consistent access; no double debit |

For each phase: pure policy tests, service tests, real-database concurrency tests where applicable, backend API tests, shared-fixture Dart contract tests and targeted widget tests. Use deterministic AI stubs for branch coverage, then a separate small live-quality evaluation. Do not add tests that merely duplicate field assignments.

Before completion run the full backend suite, full Flutter suite and `flutter analyze`, plus iOS/Android smoke checks for navigation, notifications and purchases. Compare against the baseline and require no new regressions. Existing tests asserting one-tap unknown-food logging must be updated to the intentional portion-review behavior, not silently deleted.

Ship as ordered reviewable changes: (1) contracts/atomic state, (2) logging/proposal lifecycle, (3) recommendation policy, (4) UX, (5) monetization/measurement. Each change needs its acceptance scenarios passing before dependent work proceeds. Release backend and client as a matched version; no compatibility implementation is planned.

Completion requires demonstrated behavior in the matrix, not merely successful compilation. Defer extra recipe discovery, camera expansion, precise pantry inventory and broad architectural rewrites until these guarantees hold.
