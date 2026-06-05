# Onboarding Module

## Responsibilities

- Present a first-launch onboarding carousel (3 pages) introducing the app.
- Let the user page through, skip, or finish onboarding.
- Signal completion back to the composition root via a single callback.

This module is presentation-only: no backend, no repository, no network.

## Public Contracts

- Factory Entry Point:
  - `OnboardingModule.makeOnboardingView(onFinish:) -> some View` — builds
    `OnboardingView` wired to an `OnboardingViewModel`.
- Completion Callback:
  - `onFinish: () -> Void` — invoked once when the user taps "Done" on the last
    page (`next()` on `isLastPage`) or "Skip" on any earlier page. `RootView`
    passes a closure that calls `authStateManager.markOnboardingComplete()`.

## Data Dependencies

None — no endpoints, repository, DTOs, or networking. Content is hardcoded in
`OnboardingViewModel.pages`.

## Domain Models

- `OnboardingPage` — value type with `symbol: String` (SF Symbol name),
  `title: Localized.Onboarding`, `subtitle: Localized.Onboarding`.
  Three pages: `camera.viewfinder`, `sparkles`, `tag.fill`. Strings come from
  the `Localized.Onboarding` catalog (keys `onboarding.page{1,2,3}.{title,subtitle}`).

## Flow

```
RootView (phase == .onboarding)
  → OnboardingModule.makeOnboardingView { markOnboardingComplete() }
      OnboardingView (TabView, page style) → next()/skip()
        ↓ onFinish()
  AuthStateManager.markOnboardingComplete()
        ↓ (phase → .authenticated if tokens stored, else .unauthenticated)
RootView re-renders auth/main flow
```

`AuthStateManager` enters `.onboarding` at init only when the persisted flag is
false **and** the `onboardingEnabled` feature flag is on; otherwise it goes
straight to `.authenticated`/`.unauthenticated`.

## Error Handling

None — no fallible operations, no `OnboardingError`, no error states.

## Persistence

- Completion is persisted by `AuthStateManager.markOnboardingComplete()` in
  `UserDefaults.standard`, bool key `"onboarding_completed"`
  (`AuthStateManager.onboardingCompletedKey`).
- On next launch the manager reads this key; `true` skips the onboarding phase.
- UserDefaults is wiped on app uninstall, so a reinstall re-shows onboarding.
- The `.onboardingEnabled` feature flag (`FeatureFlagKey.onboardingEnabled`,
  default `true` in `LocalFeatureFlagClient`) gates whether onboarding is shown.

## Analytics

None — no analytics events are emitted from this module.

## Open Questions / TODO

None.
