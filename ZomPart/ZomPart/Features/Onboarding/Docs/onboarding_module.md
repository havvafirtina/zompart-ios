# Onboarding Module

## Responsibilities

- Present a first-launch onboarding carousel (3 pages) introducing the app.
- Let the user page through with "Next", "Skip" earlier pages, or "Done" on the
  last page.
- Signal completion back to the composition root via a single `onFinish` callback.

This module is presentation-only. It has no Data layer (no endpoints,
repositories, DTOs, or networking), no Domain layer (no `OnboardingError`, no
repository protocol), and no Docs-described backend contract. The only files are
the module factory and the three Presentation files:

```
Features/Onboarding/
├── OnboardingModule.swift                  — static factory (composition root)
├── Presentation/
│   ├── OnboardingView.swift                — TabView carousel + buttons
│   ├── OnboardingPageView.swift            — single page (symbol, title, subtitle)
│   └── OnboardingViewModel.swift           — state + onFinish callback + OnboardingPage
└── Docs/onboarding_module.md
```

Note: the `OnboardingPage` value type is declared at the bottom of
`OnboardingViewModel.swift`; there is no separate `Models/` file.

## Public Contracts

- Factory Entry Point:
  - `OnboardingModule.makeOnboardingView(onFinish: @escaping () -> Void) -> some View`
    (`@MainActor`) — builds `OnboardingView` wired to an `OnboardingViewModel`.
- Completion Callback:
  - `onFinish: () -> Void` — invoked exactly once, when the user taps "Done" on
    the last page (`next()` while `isLastPage`) or "Skip" on any earlier page
    (`skip()`). The view does not dismiss itself; `RootView` reacts to the auth
    phase change instead.
  - `RootView` passes a closure that calls
    `authStateManager.markOnboardingComplete()`.

## Domain Models

- `OnboardingPage` — value type (struct) with:
  - `symbol: String` — SF Symbol name rendered at `.system(size: 80)`.
  - `title: Localized.Onboarding` — localized title key.
  - `subtitle: Localized.Onboarding` — localized subtitle key.
- The three pages are hardcoded in `OnboardingViewModel.pages`:

```
1. symbol "camera.viewfinder"
   title    onboarding.page1.title    → "Identify Your Part"
   subtitle onboarding.page1.subtitle → "Take a photo of the broken part and let
                                         AI identify it for you"
2. symbol "sparkles"
   title    onboarding.page2.title    → "Compare Prices"
   subtitle onboarding.page2.subtitle → "Get offers from multiple vendors sorted
                                         by price, speed, or recommendation"
3. symbol "tag.fill"
   title    onboarding.page3.title    → "Save Time & Money"
   subtitle onboarding.page3.subtitle → "Find the best deal without calling
                                         dozens of shops"
```

English values shown above; `en`, `sv`, and `tr` translations exist in
`Resources/Localization/Localizable.xcstrings` (all marked `extractionState:
stale`).

## Presentation / Flow

`OnboardingViewModel` (`@Observable`, `@MainActor`) state:

- `currentPage: Int` — selected page index, default `0`. Two-way bound to the
  `TabView` selection (`$viewModel.currentPage`), so swiping updates it.
- `pages: [OnboardingPage]` — the three hardcoded pages above.
- `isLastPage: Bool` — computed, `currentPage == pages.count - 1`.
- `onFinish: () -> Void` — private stored callback injected via `init`.
- `next()` — if `isLastPage`, calls `onFinish()`; otherwise increments
  `currentPage`.
- `skip()` — always calls `onFinish()` (no page-index change).

`OnboardingView`:

- `TabView` with `.tabViewStyle(.page(indexDisplayMode: .always))` showing page
  dots, iterating `viewModel.pages.enumerated()` keyed by `\.offset`, each
  tagged by index.
- A bottom button bar:
  - "Skip" (`Localized.Common.skip`) — shown only when `!isLastPage`; calls
    `viewModel.skip()`; styled `Color.sbTextSecondary`.
  - Primary button — calls `viewModel.next()`; label is `Localized.Common.done`
    when `isLastPage`, otherwise `Localized.Common.next`. Styled with
    `Color.sbAccentPrimary` background / `Color.sbTextOnAccent` text.
- Background `Color.sbSurfacePrimary`.

`OnboardingPageView` renders one page centered between spacers: the SF Symbol in
`Color.sbAccentPrimary`, the title (`.sbTitleSemiboldXLarge`,
`Color.sbTextPrimary`), and the subtitle (`.sbBodyRegularDefault`,
`Color.sbTextSecondary`). Title/subtitle are rendered via `page.title.localizedKey`
/ `page.subtitle.localizedKey` (a `LocalizedStringKey`), whereas the buttons use
`Localized.Common.*.localized` (a resolved `String`). Styling tokens come from the
`SBDesignSystem` package.

End-to-end flow:

```
RootView (authStateManager.phase == .onboarding)
  → OnboardingModule.makeOnboardingView { authStateManager.markOnboardingComplete() }
      OnboardingView (TabView page style)
        → next() on last page  → onFinish()
        → skip() on any page    → onFinish()
        ↓
  AuthStateManager.markOnboardingComplete()
        ↓ persists flag, then sets phase →
            .authenticated  (if tokenProvider.hasStoredTokens)
            .unauthenticated (otherwise)
RootView re-renders the auth flow or main tab view
```

`AuthStateManager` enters `.onboarding` at init only when the persisted
`onboarding_completed` flag is `false` AND the `onboardingEnabled` feature flag
is `true`; otherwise it routes straight to `.authenticated` (if stored tokens) or
`.unauthenticated`.

## Error Handling

None — there are no fallible operations, no `OnboardingError`, and no error UI in
this module.

## Persistence

- Onboarding completion is persisted by `AuthStateManager.markOnboardingComplete()`
  in `UserDefaults.standard` under the bool key `"onboarding_completed"`
  (`AuthStateManager.onboardingCompletedKey`).
- At init, `AuthStateManager` reads that key; `true` skips the `.onboarding` phase.
- The persistence and the entry decision live entirely in
  `Core/Auth/AuthStateManager.swift`; the Onboarding module itself writes nothing.
- `UserDefaults` is wiped on app uninstall, so a reinstall re-shows onboarding.
- Related (separate) flag: `AuthStateManager` also tracks a fresh-install flag
  `"app_launched_before"` (`launchedBeforeKey`) to clear stale Keychain tokens on
  reinstall. This is not the onboarding flag, but it runs in the same `init`
  before the onboarding decision.

## Feature Flag

- `FeatureFlagKey.onboardingEnabled` gates whether onboarding is shown.
- `AuthStateManager` reads it via `featureFlags.bool(for: .onboardingEnabled)`.
- `LocalFeatureFlagClient` returns `true` for `onboardingEnabled` (the only flag
  defined), so onboarding is enabled by default.

## Analytics

No analytics events defined for this scope. A module-wide grep for
`Analytics` / `SBAnalytics` / `track(` returns no matches in
`Features/Onboarding`.

## Open Questions / TODO

- The onboarding `.xcstrings` entries are marked `extractionState: stale`; they
  resolve correctly but are flagged for re-extraction in the catalog.
