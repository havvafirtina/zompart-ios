# Auth Module

## Responsibilities

- Send email OTP for signup or login via `auth-otp`.
- Verify OTP and obtain session tokens via `auth-verify`.
- Refresh expired session tokens via `auth-refresh`.
- Logout with configurable scope via `auth-logout`.
- Initiate and confirm account deletion via `auth-delete-request` / `auth-delete-confirm`.

## Public Contracts

- Domain Interfaces:
  - `AuthRepositoryProtocol` (`sendOTP`, `verifyOTP`, `refreshToken`, `logout`, `requestAccountDeletion`, `confirmAccountDeletion`)
- Navigation Entry Points:
  - `EmailOTPAuthView` — email input + OTP send (used from `RootView` auth flow)
  - `OTPVerifyView` — code entry + verify (presented by `RootView` after OTP send)

## Data Dependencies

- Endpoints (all POST):
  - `AuthOTPEndpoint` — `/functions/v1/auth-otp` (body: `email`, `intent`, `first_name`, `last_name`)
  - `AuthVerifyEndpoint` — `/functions/v1/auth-verify` (body: `email`, `token`, `type: "email"`)
  - `AuthRefreshEndpoint` — `/functions/v1/auth-refresh` (body: `refresh_token`; no Bearer required)
  - `AuthLogoutEndpoint` — `/functions/v1/auth-logout` (body: `scope`; requires Bearer)
  - `AuthDeleteRequestEndpoint` — `/functions/v1/auth-delete-request` (empty body; requires Bearer)
  - `AuthDeleteConfirmEndpoint` — `/functions/v1/auth-delete-confirm` (body: `email`, `token`, `type: "email"`)
- Networking:
  - Uses SBNetworking `HTTPClient`. `apikey` header + Bearer token are injected at app level via `ZomPartAuthTokenProvider`.

## Domain Models

- `AuthOTPResultDomain` — OTP send confirmation (`id`)
- `AuthSessionDomain` — `accessToken`, `refreshToken`, `expiresIn`
- `AuthOTPIntent` — `.signup` | `.login`
- `AuthLogoutScope` — `.local` | `.global` | `.others`
- `AuthDeleteRequestDomain` — `expiresInMinutes`

## Auth Flow

```
EmailOTPAuthView → sendOTP() → onOTPSent(email, name?)
  ↓ (RootView sets pendingVerifyEmail, presents verify)
OTPVerifyView → verify() → onVerified(AuthSessionDomain)
  ↓ (RootView stores tokens, calls authStateManager.didAuthenticate)
AuthStateManager.phase = .authenticated → MainTabView
```

`onOTPSent` carries `(email, fullName?)`; the name is forwarded to `didAuthenticate` after verification.

## Error Handling

`AuthError` maps `HTTPClientError` cases per operation. `HTTPClient` surfaces dedicated cases for
401 (`.unauthorized`), 404 (`.notFound`), and 500+ (`.serverError(statusCode:)`); other 4xx arrive as
`.clientError(statusCode:data:)`. Repositories validate `envelope.success` and `envelope.data != nil`
before calling `toModel()`. Error bodies are parsed via `APIErrorParser.code(from:)` for granular cases.

| Case | Trigger |
|---|---|
| `.emailAlreadyRegistered` | 409 on OTP send |
| `.emailNotRegistered` | `.notFound` on OTP send |
| `.validationFailed` | any other `.clientError` on OTP send (e.g. `MISSING_FIELDS`, `INVALID_INTENT`, `SIGNUP_METADATA_REQUIRED`) |
| `.otpInvalid` | any non-429 `.clientError` on verify |
| `.deletionRequestExpired` | 410 on delete confirm, or `REQUEST_EXPIRED` code |
| `.deletionFailed` | `.serverError` 500 on delete confirm |
| `.noPendingDeletionRequest` | other `.clientError` on delete confirm (`NO_PENDING_REQUEST`) |
| `.tokenExpired` | `.unauthorized` on verify / refresh / logout / delete |
| `.rateLimitExceeded` | 429 on any endpoint |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` |
| `.emptyResponse` | nil envelope or `success == false` / `data == nil` |
| `.unknown` | all other errors |

ViewModels surface a subset: `EmailOTPAuthViewModel` shows messages for `.validationFailed`,
`.emailAlreadyRegistered`, `.emailNotRegistered`, `.network` (else unknown); `OTPVerifyViewModel`
shows `.otpInvalid`, `.tokenExpired`, `.network` (else unknown).

## Backend Error Codes (from Supabase, for reference)

- `MISSING_FIELDS`, `INVALID_INTENT`, `SIGNUP_METADATA_REQUIRED`, `EMAIL_ALREADY_REGISTERED`
- `EMAIL_NOT_REGISTERED`, `VERIFY_FAILED`, `REFRESH_FAILED`
- `NO_PENDING_REQUEST`, `REQUEST_EXPIRED`, `DELETE_FAILED`, `RATE_LIMIT_EXCEEDED`, `UNAUTHORIZED`

## Analytics

- No analytics events defined for this scope.

## DTOs

- `AuthOTPDataDTO` — `{ id }` → `AuthOTPResultDomain`
- `AuthSessionDataDTO` — `{ access_token, refresh_token, expires_in }` → `AuthSessionDomain`; shared by
  `auth-verify` and `auth-refresh` (`AuthRefreshDataDTO` is a typealias of it).
- `AuthLogoutDataDTO` — `{ logged_out }` → `Bool`
- `AuthDeleteRequestDataDTO` — `{ expires_in_minutes }` → `AuthDeleteRequestDomain`
- `AuthDeleteConfirmDataDTO` — `{ deleted }` → `Bool`

## Token Refresh

`ZomPartAuthTokenProvider.refresh()` is invoked by `HTTPClient` on 401 responses. It POSTs to
`/functions/v1/auth-refresh` directly via `URLSession` (bypassing `HTTPClient` to avoid recursion),
deduplicating concurrent attempts through a shared `pendingRefresh` task. On success, tokens are
updated and persisted transparently and the original request is retried. On failure, tokens are
cleared, the `onAuthInvalidated` callback fires (wired in `RootView` to `AuthStateManager`, routing
back to login), and `.unauthorized` is thrown.

## Persistence

- Tokens are persisted in the Keychain via `KeychainTokenStore` (`TokenPersistence`), keyed under
  service `com.zompart.auth` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- `ZomPartAuthTokenProvider` loads stored tokens on init and mirrors them into memory under a lock.
- `clearTokens()` wipes both memory and Keychain (used on logout and refresh failure).
- `AuthStateManager` clears Keychain tokens on a detected fresh install (UserDefaults `launchedBefore`
  flag) so reinstalls don't resurrect stale tokens.

## Open Questions / TODO

- Add account deletion UI screens (repository methods exist; no SwiftUI screens wired yet).
