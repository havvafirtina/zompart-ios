# Profile Module

## Responsibilities

- Display the current user's identity (email + optional name) read from `AuthStateManager`.
- Switch the app *theme* (color palette) and *appearance* (light/dark/system) via `ThemeManager`.
- Switch the app language (English / Svenska / Türkçe) and prompt the user to restart.
- Show the app version and legal links (Privacy Policy / Terms of Service) on an About screen.
- Log out: best-effort server call followed by an unconditional local session clear.
- Delete the account through a two-step OTP-confirmed flow.

This module owns **no Data layer**. It has no endpoints, DTOs, repositories, or domain models of
its own. For all network work it reuses the Auth module's `AuthRepositoryProtocol`, and for app
state it reuses `AuthStateManager` and `ThemeManager` from Core.

## Public Contracts

- Factory: `ProfileModule` (an `enum` with static `@MainActor` factory methods):
  - `makeProfileMainViewModel(authRepository:authStateManager:) -> ProfileMainViewModel`
  - `makeDeleteAccountViewModel(authRepository:authStateManager:) -> DeleteAccountViewModel`
- External dependencies it composes:
  - `AuthRepositoryProtocol` (Auth module) — logout + account deletion calls.
  - `AuthStateManager` (Core) — supplies `userEmail` / `userName` at construction and performs
    `logout()` to clear the local session and flip the auth phase.
  - `ThemeManager` (Core) — passed directly into the views (`ProfileMainView`, `ThemePickerView`);
    it is not injected through a Profile ViewModel.

The ViewModels are constructed lazily in `Core/Navigation/ViewModelCache.swift`, which calls the
`ProfileModule` factories with `AuthModule.makeAuthRepository(httpClient:)` and the app-level
`authStateManager`. `Core/Navigation/MainTabView.swift` wires the screens together.

## Screens & ViewModels

### ProfileMainView + ProfileMainViewModel

Root screen of the Profile tab; an inset-grouped `List` with five sections:

- **User info** — shows `userName` (only when non-empty) and `userEmail`. Both values are
  captured from `AuthStateManager` when the ViewModel is created (`let` constants, not reactive).
- **Appearance** — two rows:
  - *Theme* row: a button showing `themeManager.currentTheme.rawValue.capitalized`; tapping it
    invokes the `onTheme` closure, which pushes the theme picker.
  - *Appearance mode* row: an inline `.menu` `Picker` bound straight to
    `themeManager.appearancePreference` with `SBAppearancePreference.system / .light / .dark` tags
    (no navigation — changes apply immediately).
- **Language** — a button that invokes `onLanguage` to push the language picker.
- **About** — a button that invokes `onAbout` to push the About screen.
- **Account** — two destructive buttons:
  - *Logout* → calls `viewModel.requestLogout()`, which sets `showLogoutConfirm = true`,
    surfacing a confirmation `.alert`. Confirming runs `Task { await viewModel.confirmLogout() }`.
  - *Delete Account* → invokes `onDeleteAccount` to push the delete-account flow.

The whole list is disabled while `viewModel.isLoggingOut` is `true`.

`ProfileMainViewModel` (`@Observable`, `@MainActor`) state:

- `userEmail: String`, `userName: String` — immutable identity snapshots.
- `showLogoutConfirm: Bool` — drives the confirmation alert (bindable).
- `isLoggingOut: Bool` — `private(set)`, disables the UI during logout.
- `requestLogout()` — just flips `showLogoutConfirm = true`.
- `confirmLogout()` — sets `isLoggingOut`, attempts `authRepository.logout(scope: .local)` inside a
  `do/catch` that **swallows any error**, then unconditionally calls `authStateManager.logout()`
  and clears `isLoggingOut`.

### ThemePickerView

A three-column `LazyVGrid` over `SBTheme.allCases`. Each cell shows a colored preview circle (from
a local `previewColors` map keyed by `SBTheme`), the capitalized theme name, and a checkmark plus a
colored border when selected. Tapping a cell sets `themeManager.currentTheme = theme` (persisted by
the manager). The scroll background uses a local pastel `surfaceColors` map per theme. The picker
takes `ThemeManager` directly (no ViewModel).

### LanguagePickerView

A plain `List` of three hard-coded languages: `("en", "English")`, `("sv", "Svenska")`,
`("tr", "Türkçe")`. The initially-selected row is derived from
`Locale.preferredLanguages.first?.prefix(2)` (defaulting to `"en"`). Selecting a different language
calls `selectLanguage(_:)`, which writes `[code]` to the `UserDefaults` key `"AppleLanguages"`,
calls `synchronize()`, and shows a restart-required alert. The change only takes effect on the next
launch (no live re-localization). This view owns no ViewModel and does not touch the network.

### AboutView

A `List` with two sections:

- App version: `"<CFBundleShortVersionString> (<CFBundleVersion>)"`, defaulting to `"1.0"` / `"1"`
  when the Info.plist keys are missing.
- Privacy Policy and Terms of Service rows. Both currently open the **placeholder URL**
  `https://www.google.com` in an in-app `SafariView`, presented as a sheet via an
  `IdentifiableURL` (`@State`). This view owns no ViewModel.

### DeleteAccountView + DeleteAccountViewModel

Two-step, OTP-confirmed account deletion. The view switches on `viewModel.phase`:

- `.confirm` — warning icon, confirm title/message, and a destructive button that runs
  `await viewModel.requestDeletion()`. Shows an inline error if `state == .error`.
- `.otpSent` — an envelope icon, an "OTP sent" message, a numeric `TextField` bound to
  `viewModel.otpCode`, and a confirm button (disabled while `otpCode` is empty) that runs
  `await viewModel.confirmDeletion()`. Shows an inline error if `state == .error`.
- `.deleting` — a centered `ProgressView`.

The view is disabled while `viewModel.state == .loading`.

`DeleteAccountViewModel` (`@Observable`, `@MainActor`) state:

- `phase: Phase` (`.confirm` → `.otpSent` → `.deleting`), `private(set)`.
- `state: ViewState<Bool>` — `.idle` / `.loading` / `.loaded(true)` / `.error(String)`, `private(set)`.
- `otpCode: String` — bindable.
- `userEmail: String` — captured at init, used as the confirm email.

Flow:

1. `requestDeletion()` — sets `.loading`, calls `authRepository.requestAccountDeletion()`. On
   success moves to `phase = .otpSent` and `state = .idle`. On `AuthError`, sets
   `state = .error(error.deletionErrorMessage)`; on any other error, `state = .error(Localized.Error.unknown.localized)`.
2. `confirmDeletion()` — returns early if `otpCode` is empty; otherwise sets `.loading` and
   `phase = .deleting`, then calls `authRepository.confirmAccountDeletion(email: userEmail, token: otpCode)`.
   On success sets `state = .loaded(true)` and calls `authStateManager.logout()` (which clears
   tokens + identity and flips the auth phase to `.unauthenticated`, routing the user back to the
   login flow via `RootView`). On failure it **reverts to `phase = .otpSent`** and sets an error
   (`AuthError` → `deletionErrorMessage`, otherwise `Localized.Error.unknown`), so the user can
   retry with a fresh code.

## Data Dependencies

Profile defines no endpoints. It reaches the backend only through `AuthRepositoryProtocol`
(implemented by the Auth module's `AuthRepository`, an `actor`):

| Repo method | HTTP | Path | Used by |
|---|---|---|---|
| `logout(scope: .local)` | POST | `/functions/v1/auth-logout` | `ProfileMainViewModel.confirmLogout()` |
| `requestAccountDeletion() -> AuthDeleteRequestDomain` | POST | `/functions/v1/auth-delete-request` | `DeleteAccountViewModel.requestDeletion()` |
| `confirmAccountDeletion(email:token:)` | POST | `/functions/v1/auth-delete-confirm` | `DeleteAccountViewModel.confirmDeletion()` |

The `AuthDeleteRequestDomain` returned by `requestAccountDeletion()` is discarded (`_ =`); only the
success/throw outcome matters to this module.

## Domain Models

None. Profile defines no domain models. UI state uses the shared `ViewState<Bool>` (Core) for the
delete-account flow. The theme/appearance enums (`SBTheme`, `SBAppearancePreference`) come from the
`SBDesignSystem` package, not this module.

## Error Handling

Profile does not map HTTP status codes itself; all mapping happens inside the Auth repository
(`HTTPClientError` → `AuthError`). The relevant repository mappings are:

- `auth-delete-confirm` (`mapDeleteConfirmError`): `410` → `.deletionRequestExpired`;
  `500` → `.deletionFailed`; `429` → `.rateLimitExceeded`; `401` → `.tokenExpired`; body code
  `request_expired` → `.deletionRequestExpired`; body code `no_pending_request` (and any other
  client error) → `.noPendingDeletionRequest`; offline → `.network`; else `.unknown`.
- `auth-delete-request` and `auth-logout` (`mapTokenError`): `401` → `.tokenExpired`;
  `429` → `.rateLimitExceeded`; offline → `.network`; else `.unknown`.

`DeleteAccountViewModel` translates the resulting `AuthError` to a user-facing string through a
private `AuthError.deletionErrorMessage`:

| `AuthError` | Message key |
|---|---|
| `.noPendingDeletionRequest` | `Localized.Profile.errorNoPendingDeletion` |
| `.deletionRequestExpired` | `Localized.Profile.errorDeletionRequestExpired` |
| `.deletionFailed` | `Localized.Profile.errorDeletionFailed` |
| `.otpInvalid` | `Localized.Auth.errorOtpInvalid` |
| `.network` | `Localized.Error.network` |
| default | `Localized.Error.unknown` |

Non-`AuthError` throws fall back to `Localized.Error.unknown`. Logout is intentionally best-effort:
any thrown error is swallowed and the local session is always cleared.

## Navigation

The Profile tab is one of three tabs in `MainTabView` (`AppRouter.Tab.scan / .garage / .profile`,
icon `person.fill`), backed by its own `NavigationStack(path: $router.profilePath)`. Push
destinations are modeled by `AppRouter.ProfileRoute`:

| Route | Destination | Pushed from |
|---|---|---|
| `.theme` | `ThemePickerView` | ProfileMain `onTheme` |
| `.language` | `LanguagePickerView` | ProfileMain `onLanguage` |
| `.about` | `AboutView` | ProfileMain `onAbout` |
| `.deleteAccount` | `DeleteAccountView` | ProfileMain `onDeleteAccount` |

ViewModel lifecycle: `ProfileMainViewModel` and `DeleteAccountViewModel` are cached in
`ViewModelCache`. When `router.profilePath` becomes empty (the stack pops back to the root),
`MainTabView` calls `vmCache.invalidateDeleteAccount()`, so a fresh `DeleteAccountViewModel`
(phase reset to `.confirm`, empty `otpCode`) is built on the next entry.

## Persistence

- **Theme / appearance** — owned by `ThemeManager` (`@Observable`, `@MainActor`):
  - `currentTheme.rawValue` under `UserDefaults` key `"selected_theme"` (default `.crimson`).
  - `appearancePreference.rawValue` under key `"appearance_preference"` (default `.system`).
  - Both `didSet` observers also push the value into `SBDesignSystemManager.shared`
    (`updateTheme` / `updateAppearance`), which is also applied once at `init`.
- **Language** — `[code]` written to the system `UserDefaults` key `"AppleLanguages"`; effective on
  next launch (restart alert shown).
- **Session / identity** — cleared via `AuthStateManager.logout()`: it calls
  `tokenProvider.clearTokens()`, clears `userEmail` / `userName`, removes the `"user_email"` and
  `"user_name"` `UserDefaults` keys, and sets `phase = .unauthenticated`. Owned by Core, not this
  module.

## Analytics

- No analytics events defined for this scope.

## Open Questions / TODO

- About screen Privacy Policy and Terms of Service both point to the placeholder URL
  `https://www.google.com`.
- Language change requires a manual app restart; there is no live re-localization.
