# Feedback implementation — September 10, 2026

Branch: `feat/feedback-polish` in both the Flutter and backend repositories.
Existing uncommitted work was preserved. Changes have not been deployed.

## Changes

1. **American pantry:** added a US backend starter pack with 45 foods, including
   11 proteins and 9 fruits. Eggs are categorized as protein. Existing dietary
   filtering and canonical server-side selection remain in use. Onboarding clears
   cached pantry items so a previous session cannot hide starter choices.
2. **Sliders:** shared minus/plus controls across age, height, weight, target
   weight, and profile editors. Controls use 48px targets, bounds enforcement,
   haptics, and descriptive accessibility labels. Narrow controls put the buttons
   underneath. Profile measurements support 0.1-unit steps; age uses whole years.
3. **Splash:** 1.8-second staggered ring fill and a centered utensil collision with
   damped rotation, ending on the original static icon. Reduced-motion mode skips
   movement. The launch overlay lets initialization proceed underneath.
4. **Meal confirmation:** immediate spinner, duplicate-tap protection, inline
   failure feedback, and an operation ID retained for retries. The confirmation
   sheet opens above the tab navigation.
5. **Macro legend:** Protein, Carbs, and Fats beneath their colored values; wraps
   when larger text needs more space.
6. **Check-ins:** installed the iOS notification delegate, switched permission
   inspection to the notification plugin, made failed scheduling recoverable,
   exposed scheduling errors, refreshed timezone on sync/resume, and preserved
   pending snoozes across unrelated plan updates.
7. **Debug notification test:** Profile → Meal reminders → Developer tools →
   Test check-in now. Debug builds only. Reports permission, alerts, sound,
   timezone, pending slots, and submission/failure details. These are local iOS
   notifications, so push-token registration is not applicable. Successful
   submission does not prove that the OS displayed an alert.
8. **Final onboarding CTA:** moved “Let's get started!” into the bottom safe area.

## Verification

- Backend pantry/onboarding regression suite: 35 passed.
- Flutter full suite: 58 passed, 4 failed in unchanged welcome/setup areas.
  Three welcome tests expect a `TextButton` that the current screen does not
  contain. The setup failure test does not reach its expected retry state; the
  existing onboarding code now awaits the native timezone lookup.
- All six new regression tests pass, including a deliberately delayed meal-log
  request, duplicate prevention, retry operation identity, scheduling queue
  recovery, stepper bounds/layout, splash timing, and reduced motion.
- `flutter analyze`: one existing unused `_navBottomMargin` warning in
  `home_shell.dart`; no new findings.
- Native iOS arm64 simulator build passed using:

  ```sh
  xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO -quiet
  ```

  The default multi-architecture Flutter simulator packaging failed; no project
  architecture settings were changed to work around it.

## Device follow-up

Deploy the matching backend branch before expecting the expanded pantry in the
app. On an iPhone debug build, enable meal check-ins, test the notification while
foregrounded, then set a meal reminder a few minutes ahead and background the
app. Confirm its arrival and that tapping it opens the matching check-in. Check
Focus and Scheduled Summary if submission succeeds but a banner is not visible.
Actual device delivery and visual animation review remain unverified.
