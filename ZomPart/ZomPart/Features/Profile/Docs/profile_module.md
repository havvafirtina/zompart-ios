# Profile Module

## Responsibilities

- Display current user info (email + optional name) from `AuthStateManager`.
- Switch app theme and appearance (light/dark/system) via `ThemeManager`.
- Switch app language via `LanguagePickerView` (writes `AppleLanguages`).
- Show app version and legal links (About).
- Logout (best-effort server call + local session clear).
- Delete account through a two-step OTP confirm flow.

This module owns no Data layer. It reuses `AuthRepositoryProtocol` (from the Auth
module) and `AuthStateManager` / `ThemeManager` (from Core).

## Public Contracts

- Factory: `ProfileModule` (enum) with static `@MainActor` methods:
  - `makeProfileMainViewModel(authRepository:authStateManager:) -> ProfileMainViewModel`
  - `makeDeleteAccountViewModel(authRepository:authStateManager:) -> DeleteAccountViewModel`
- External protocols it depends on:
  - `AuthRepositoryProtocol` — for logout + account deletion
  - `AuthStateManager` — user identity + session/phase mutation
  - `ThemeManager` — theme + appearance state
- Both ViewModels are wired in `Core/Navigation/MainTabView.swift` with
  `AuthModule.makeAuthRepository(httpClient:)` and the app-level `authStateManager`.

## Data Dependencies

Profile owns no endpoints. It reaches the backend only through `AuthRepositoryProtocol`:

- `logout(scope: .local)` — POST `/functions/v1/auth-logout` (on confirm logout)
- `requestAccountDeletion()` — POST `/functions/v1/auth-delete-request` (sends deletion OTP)
- `confirmAccountDeletion(email:token:)` — POST `/functions/v1/auth-delete-confirm`

## Domain Models

None — Profile defines no domain models. It consumes Auth domain types indirectly
and uses `ViewState<Bool>` for delete-account UI state. Theme/appearance enums
(`SBTheme`, `SBAppearancePreference`) are provided by the `SBDesignSystem` package,
not by this module.

## Sub-screens

- **ProfileMainView** — root list: user info, appearance, language, about, account
  (logout + delete). Logout shows a confirmation alert before calling the ViewModel.
- **ThemePickerView** — grid of `SBTheme.allCases`; tapping sets `themeManager.currentTheme`.
- **LanguagePickerView** — picks en/sv/tr; writes `AppleLanguages` and prompts for restart.
- **AboutView** — app version (`CFBundleShortVersionString` + `CFBundleVersion`) and
  Privacy/Terms links opened via `SafariView` (currently placeholder URLs).
- **DeleteAccountView** — phased UI (`confirm` → `otpSent` → `deleting`) driven by
  `DeleteAccountViewModel`; sends OTP then confirms deletion with the entered code.

## Error Handling

- Logout is best-effort: `ProfileMainViewModel.confirmLogout()` swallows any thrown
  error and always calls `authStateManager.logout()` to clear local session.
- Delete account surfaces errors via `ViewState.error` with localized strings:
  - request failure → `Localized.Error.network`
  - confirm failure → `Localized.Auth.errorOtpInvalid` (and reverts to `.otpSent`)
- Underlying errors originate from `AuthError` mapping in the Auth repository; this
  module does not re-map status codes itself.

## Persistence

- **Theme**: `ThemeManager` stores `currentTheme.rawValue` under UserDefaults key
  `"selected_theme"` and `appearancePreference.rawValue` under `"appearance_preference"`.
  Default theme is `.crimson`; default appearance is `.system`. Applied at init via
  `SBDesignSystemManager.shared.updateTheme/updateAppearance`.
- **Language**: `LanguagePickerView.selectLanguage(_:)` writes `[code]` to the system
  UserDefaults key `"AppleLanguages"`; takes effect on next launch (restart alert shown).
- **Session/identity**: cleared via `AuthStateManager.logout()` (tokens + `user_email`
  / `user_name` UserDefaults keys), owned by Core, not this module.

## Analytics

None — no analytics events are emitted in this module.

## Open Questions / TODO

- About screen Privacy/Terms links point to placeholder `https://www.google.com` URLs.
- Language change requires a manual app restart (no live re-localization).
