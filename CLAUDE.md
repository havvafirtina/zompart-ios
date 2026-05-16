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

**Clean Architecture + MVVM** with five feature modules: Auth, Vehicle, Scan, Offer, History.

Every feature follows the same three-layer structure:

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

### Key conventions

- **Module factories** (`AuthModule`, `ScanModule`, etc.) are `enum` types with static `make*` methods. They wire repository → ViewModel and are called from `ZomPartApp.swift`.
- **Repositories** are `actor` types (implicit Sendable, thread-safe).
- **ViewModels** are `@Observable` and `@MainActor`.
- **Domain layer has no framework imports** — pure Swift models and protocols.
- Protocol names use `Protocol` suffix (e.g., `AuthRepositoryProtocol`). No prefix on concrete types.
- No app-wide prefix on type names; use `ZP` only if disambiguation is needed.

### Networking

Single external dependency: **SBNetworking** (SPM, `git@github.com:berberoglus/SBNetworking.git`).

Request flow: `RequestProtocol` → `Endpoint` (path/method/payload/ResponseType) → `APIEnvelope<DTO>` → `DTO.toModel()` → domain model.

- `APIEnvelope<T>` wraps every Supabase edge-function response: `{ success, data, meta }`.
- `ZomPartAuthTokenProvider` manages API key + session tokens with `OSAllocatedUnfairLock`.
- `DefaultEnvironment` implements `HttpClientProtocol`, reads scheme/URL from plist.
- Error mapping: each feature's `<Name>Error` enum maps `HTTPClientError` status codes to domain errors (e.g., 409 → emailAlreadyRegistered, 401 → tokenExpired).

### Composition root

`ZomPartApp.swift` creates `ZomPartAuthTokenProvider` → `DefaultEnvironment` → `HTTPClient`, then passes the client to feature module factories. Navigation is state-driven via `@State` properties on the app struct.

## SwiftLint

Configured in `.swiftlint.yml` with `only_rules` mode (allowlist). Key settings:

- **Line length**: 150
- **Indentation**: 2 spaces
- Custom rule: `@objcMembers` is forbidden (use individual `@objc`)
- `identifier_name`, `function_body_length`, `file_length` are intentionally disabled
