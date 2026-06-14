# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

The project lives in `ZomPart/ZomPart.xcodeproj` (no workspace). Build and run via Xcode or:

```bash
# Build (Debug, iPhone simulator)
xcodebuild -project ZomPart/ZomPart.xcodeproj -scheme ZomPart -sdk iphonesimulator -configuration Debug build

# Lint
swiftlint lint --config .swiftlint.yml --path ZomPart/ZomPart/
```

No test targets exist yet. The project uses `ENABLE_TESTABILITY = YES` so internal symbols are accessible when tests are added.

## Build Configuration

Environment is injected through xcconfig files in `ZomPart/ZomPart/SupportingFiles/Configs/`:

- **Base.xcconfig** — shared variables (inherited by all configs)
- **Debug.xcconfig** — dev Supabase instance, HTTP logging enabled
- **Local.xcconfig** — `http://127.0.0.1:54321` for local Supabase
- **Release.xcconfig** — production

Values are read at runtime via `PlistReader` from Info.plist: `SUPABASE_URL`, `SUPABASE_API_SCHEME`, `SUPABASE_PUBLISHABLE_KEY`, `APP_ENV`.

## Architecture

**Clean Architecture + MVVM** with seven feature modules: Auth, Vehicle, Scan, Offer, History, Onboarding, Profile.

Network-backed features (Auth, Vehicle, Scan, Offer, History) follow the same three-layer structure:

```
Features/<Name>/
├── Data/
│   ├── DTOs/          — Decodable models (ResponseProtocol), each has toModel()
│   ├── Endpoints/     — Endpoint definitions (path, method, payload, ResponseType)
│   └── Repositories/  — actor conforming to <Name>RepositoryProtocol
├── Domain/
│   ├── Interfaces/    — <Name>RepositoryProtocol
│   └── Models/        — Domain models + <Name>Error enum
├── Presentation/
│   └── Screens/       — SwiftUI views + @Observable ViewModels
├── Docs/              — <name>_module.md (contract + error mapping docs)
└── <Name>Module.swift — Static factory (composition root entry point)
```

**Onboarding** and **Profile** are presentation-only: they have no `Data`/`Domain` network layer of their own (just `Presentation/` + a `Docs/` + their `Module.swift`). Profile's account-deletion screen reuses the Auth repository; the rest of Profile is local state (theme, language, about). Onboarding is purely UI plus a "completed" flag.

### Key conventions

- **Module factories** (`AuthModule`, `ScanModule`, etc.) are `enum` types with static `make*` methods. They wire repository → ViewModel and are invoked by the navigation layer (`RootView`, `MainTabView`, and `ViewModelCache`), each receiving the `AppEnvironment` (or the `HTTPClient` from it).
- **Repositories** are `actor` types (implicit Sendable, thread-safe).
- **ViewModels** are `@Observable` and `@MainActor`.
- **Domain layer has no framework imports** — pure Swift models and protocols.
- Protocol names use `Protocol` suffix (e.g., `AuthRepositoryProtocol`). No prefix on concrete types.
- No app-wide prefix on type names; use `ZP` only if disambiguation is needed.

### Networking

Three SPM dependencies, all resolved automatically by Xcode:

- **SBNetworking** (`git@github.com:berberoglus/SBNetworking.git`) — HTTP client, endpoint/request abstractions, token-provider hook.
- **SBDesignSystem** (`git@github.com:sametberberoglu01/SBDesignSystem.git`) — colors, spacing, typography, and the `SBDesignSystemProvider` that wraps `RootView`.
- **SBAnalytics** (`git@github.com:sametberberoglu01/SBAnalytics.git`) — event tracking (no analytics call sites are wired in the feature modules yet).

Request flow: `RequestProtocol` → `Endpoint` (path/method/payload/ResponseType) → `APIEnvelope<DTO>` → `DTO.toModel()` → domain model.

- `APIEnvelope<T>` wraps every Supabase edge-function response: `{ success, data, meta }`.
- `ZomPartAuthTokenProvider` manages API key + session tokens with `OSAllocatedUnfairLock`. On a 401 it refreshes the session itself via a direct `URLSession` POST (deduplicated through a single `pendingRefresh` task) rather than going back through `HTTPClient`; on refresh failure it fires `onAuthInvalidated` so the UI routes back to login. There is no separate `auth-refresh` repository endpoint.
- `DefaultEnvironment` implements `HttpClientProtocol`, reading scheme/URL from Info.plist via `PlistReader`.
- Error mapping: each feature's `<Name>Error` enum maps `HTTPClientError` status codes (plus the body `code` parsed by `APIErrorParser`) to domain errors (e.g., 409 → emailAlreadyRegistered, 401 → tokenExpired).

### Composition root

`ZomPartApp.swift` is intentionally thin: it builds the environment and hands it to `RootView`, wrapped in `SBDesignSystemProvider`.

```
ZomPartApp
└── SBDesignSystemProvider
    └── RootView(env: AppEnvironment.build())
```

- **`AppEnvironment.build()`** (`Core/DI/`) is the wiring point. It creates `KeychainTokenStore` → `ZomPartAuthTokenProvider` → `DefaultEnvironment` → `HTTPClient`, plus `LocalFeatureFlagClient` and `AppConfig.current()`, and exposes them as a `Sendable` struct (`httpClient`, `tokenProvider`, `featureFlags`, `config`).
- **`RootView`** owns `AuthStateManager`, `ThemeManager`, and `AppRouter` as `@State`, and switches on `authStateManager.phase`:
  - `.onboarding` → `OnboardingModule.makeOnboardingView`
  - `.unauthenticated` → the email-OTP auth flow (`EmailOTPAuthView` / `OTPVerifyView`)
  - `.authenticated` → `MainTabView`
  It also binds `tokenProvider.onAuthInvalidated` to `AuthStateManager` so a failed refresh routes back to login.
- **`MainTabView`** is the authenticated shell: three tabs (`scan`, `garage`, `profile`), each its own `NavigationStack` whose path lives on `AppRouter` (`scanPath` / `garagePath` / `profilePath`). Routes are the `AppRouter.ScanRoute` / `GarageRoute` / `ProfileRoute` enums.
- **`ViewModelCache`** (`Core/Navigation/`) owns the destination ViewModels keyed by route identity (e.g. per `scanId`, per `vehicleId`) and provides the invalidation entry points (`invalidateHistory`, `invalidateScanDetail`, etc.) that keep the History/Offer caches coherent after a scan completes.

### Core layer (`ZomPart/ZomPart/Core/`)

Cross-feature infrastructure, no feature-specific logic:

- **`DI/`** — `AppEnvironment` (composition root), `AppConfig` (reads `APP_ENV`).
- **`Auth/`** — `AuthStateManager` (the onboarding/unauthenticated/authenticated phase machine, fresh-install Keychain reset, sign-out).
- **`Navigation/`** — `RootView`, `MainTabView`, `AppRouter`, `ViewModelCache`.
- **`Networking/`** — `DefaultEnvironment`, `ZomPartAuthTokenProvider`, `APIErrorParser`, and the `DTOs/` (`APIEnvelope`, `APIMeta`).
- **`Security/`** — `KeychainTokenStore` (token persistence under service `com.zompart.auth`).
- **`FeatureFlags/`** — `FeatureFlagClient` protocol + `LocalFeatureFlagClient`; `FeatureFlagKey` (currently `onboardingEnabled`).
- **`UI/`** — `ThemeManager`, `ViewState`, `SafariView`.
- **`Localization/`** — `Localized` (typed key accessors) + `LocalizableContent`.
- **`Services/`** — `CameraPermissionManager`, `OCRService` (used by Vehicle's VIN/plate scanners and Scan's photo OCR).
- **`Utils/`** — `PlistReader`, `UIImage+Resize`.

## SwiftLint

Configured in `.swiftlint.yml` with `only_rules` mode (allowlist). Key settings:

- **Line length**: 150
- **Indentation**: 4 spaces
- Custom rule: `@objcMembers` is forbidden (use individual `@objc`)
- `identifier_name`, `function_body_length`, `file_length` are intentionally disabled
