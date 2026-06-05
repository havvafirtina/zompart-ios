# ZomPart

ZomPart is an iOS app that helps you **identify a vehicle spare part from a photo or a short text description and receive offers for it**. You add your vehicles to a garage, scan the part you need, and the app resolves it (with AI/OCR), disambiguates when the result is unclear, and surfaces matching offers — keeping a history of every scan.

## What it does

The app is organized into three tabs — **Scan**, **Garage**, and **Profile** — behind a passwordless login.

- **Onboarding & Auth** — A short intro on first launch, then sign-in via email one-time code (OTP). No passwords.
- **Garage** — Add and manage your vehicles. In the current iOS client a vehicle is added by scanning its **VIN** or **license plate**, using the camera with on-device live text recognition. (The backend and app also support person/company-number and a manual year → make → model → trim → engine wizard, but those entry points aren't exposed in the UI yet.)
- **Scan** — Pick a vehicle and identify the part you need, either by **taking photos** or by **typing a description**. The backend processes the input and returns one of:
  - **Offers ready** — the part was identified; jump straight to offers.
  - **Disambiguation** — several candidates match; you pick the right one.
  - **Failed** — retry, switch to text search, or go back.
- **Offers** — Browse offers for the identified part.
- **History** — Review past scans and open any scan's detail.
- **Profile** — Switch theme and language, read the about page, or delete your account.

## Architecture

Clean Architecture + MVVM, with one vertical slice per feature (`Auth`, `Vehicle`, `Scan`, `Offer`, `History`, `Onboarding`, `Profile`). Each feature is split into `Data` (DTOs, endpoints, repositories), `Domain` (models, protocols, errors), and `Presentation` (SwiftUI views + `@Observable` view models), wired together by a static module factory.

- **UI**: SwiftUI, navigation is fully state-driven (`AuthStateManager` phase + an `AppRouter` per-tab `NavigationStack`).
- **Concurrency**: repositories are `actor` types; view models are `@Observable` and `@MainActor`.
- **Networking**: `SBNetworking` over a Supabase edge-function backend. Every response is wrapped in an `APIEnvelope<T>` and mapped DTO → domain model.
- **Design system**: `SBDesignSystem` for colors, spacing, and typography.
- **Analytics**: `SBAnalytics` for event tracking.

See [`CLAUDE.md`](CLAUDE.md) and each feature's `Docs/*.md` for the detailed contracts.

## Build & Run

The project lives in `ZomPart/ZomPart.xcodeproj` (no workspace). Open it in Xcode, or build from the command line:

```bash
# Build (Debug, iPhone simulator)
xcodebuild -project ZomPart/ZomPart.xcodeproj -scheme ZomPart -sdk iphonesimulator -configuration Debug build

# Lint
swiftlint lint --config .swiftlint.yml --path ZomPart/ZomPart/
```

## Configuration

Environment values are injected via xcconfig files in `ZomPart/ZomPart/SupportingFiles/Configs/` (`Base`, `Debug`, `Local`, `Release`) and read at runtime from `Info.plist`: `SUPABASE_URL`, `SUPABASE_API_SCHEME`, `SUPABASE_PUBLISHABLE_KEY`, `APP_ENV`. Use `Local.xcconfig` to point the app at a local Supabase instance.

## Requirements

- Xcode (recent), iOS deployment target as configured in the project
- Swift Package dependencies (resolved automatically by Xcode): `SBNetworking`, `SBDesignSystem`, `SBAnalytics`
