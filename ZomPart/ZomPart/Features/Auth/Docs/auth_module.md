# Auth Module

## Responsibilities

- Send email OTP for signup or login via `auth-otp`.
- Verify OTP and obtain session tokens via `auth-verify`.
- Logout with a configurable scope via `auth-logout`.
- Initiate and confirm account deletion via `auth-delete-request` / `auth-delete-confirm`.

Token refresh is **not** a repository responsibility. It is handled at the network layer
inside `ZomPartAuthTokenProvider` (see "Token Refresh"), not through this module's repository.

## Public Contracts

- Domain Interfaces:
  - `AuthRepositoryProtocol` (`sendOTP`, `verifyOTP`, `logout`, `requestAccountDeletion`,
    `confirmAccountDeletion`) — `Sendable`. Exact signatures:

    ```swift
    func sendOTP(
        email: String,
        intent: AuthOTPIntent,
        firstName: String?,
        lastName: String?
    ) async throws -> AuthOTPResultDomain

    func verifyOTP(email: String, token: String) async throws -> AuthSessionDomain

    func logout(scope: AuthLogoutScope) async throws

    func requestAccountDeletion() async throws -> AuthDeleteRequestDomain

    func confirmAccountDeletion(email: String, token: String) async throws
    ```

- Module Factory (`AuthModule`, an `enum` with static methods):
  - `makeAuthRepository(httpClient:) -> AuthRepositoryProtocol`
  - `makeEmailOTPAuthViewModel(env:onOTPSent:) -> EmailOTPAuthViewModel`
    (`onOTPSent` is `(String, String?) -> Void`)
  - `makeOTPVerifyViewModel(env:email:onVerified:) -> OTPVerifyViewModel`
    (`onVerified` is `(AuthSessionDomain) -> Void`)
- Navigation Entry Points:
  - `EmailOTPAuthView` — email input + OTP send (used from `RootView` auth flow)
  - `OTPVerifyView` — code entry + verify (presented by `RootView` after OTP send)

## Data Dependencies

- Endpoints (all POST):
  - `AuthOTPEndpoint` — `/functions/v1/auth-otp`
    (body: `email`, `intent`, `first_name`, `last_name`)
  - `AuthVerifyEndpoint` — `/functions/v1/auth-verify`
    (body: `email`, `token`, `type: "email"`)
  - `AuthLogoutEndpoint` — `/functions/v1/auth-logout` (body: `scope`; requires Bearer)
  - `AuthDeleteRequestEndpoint` — `/functions/v1/auth-delete-request`
    (no body / `payload == nil`; requires Bearer)
  - `AuthDeleteConfirmEndpoint` — `/functions/v1/auth-delete-confirm`
    (body: `email`, `token`, `type: "email"`)

  There is **no** `auth-refresh` endpoint in this module. The refresh call is issued
  directly by `ZomPartAuthTokenProvider` (see "Token Refresh").

  Each endpoint has a paired `RequestProtocol` value (`AuthOTPRequest`, `AuthVerifyRequest`,
  `AuthLogoutRequest`, `AuthDeleteRequestRequest`, `AuthDeleteConfirmRequest`) that converts
  to the endpoint via `toEndpoint()`. The exact wire keys are produced by private `Encodable`
  request bodies inside each endpoint file (e.g. `first_name` / `last_name` via `CodingKeys`,
  and a constant `type: "email"` for verify and delete-confirm).
- Networking:
  - Uses SBNetworking `HTTPClient`. The `apikey` header and the Bearer token are injected at
    app level via `ZomPartAuthTokenProvider` (an `AuthTokenProvider`) wired into
    `DefaultEnvironment` → `HTTPClient` in `AppEnvironment.build()`.
  - Every response is wrapped in `APIEnvelope<DTO>` (`{ success, data, meta }`).

## Domain Models

- `AuthOTPResultDomain` — OTP send confirmation; fields: `id: String`. (`Equatable, Sendable`)
- `AuthSessionDomain` — `accessToken: String`, `refreshToken: String`, `expiresIn: Int`.
  (`Equatable, Sendable`) Returned by `verifyOTP`.
- `AuthOTPIntent` — `String`-backed `Encodable, Sendable` enum: `.signup` ("signup") |
  `.login` ("login").
- `AuthLogoutScope` — `String`-backed `Encodable, Sendable` enum with a single case:
  `.local` ("local"). The backend contract also accepts `global` and `others`, but the app
  only declares and sends `.local`.
- `AuthDeleteRequestDomain` — `expiresInMinutes: Int`. (`Equatable, Sendable`) Returned by
  `requestAccountDeletion`.
- `AuthError` — feature error enum (see "Error Handling").

## Auth Flow

```
EmailOTPAuthView → viewModel.sendOTP() → onOTPSent(email, fullName?)
  ↓ (RootView sets pendingVerifyEmail / pendingUserName, swaps to verify)
OTPVerifyView → viewModel.verify() → onVerified(AuthSessionDomain)
  ↓ (RootView calls env.tokenProvider.updateTokens(...), clears pendingVerifyEmail,
     calls authStateManager.didAuthenticate(email:name:))
AuthStateManager.phase = .authenticated → MainTabView
```

- The two auth screens are not pushed onto a navigation stack. `RootView.authFlow` is a
  `@ViewBuilder` that shows `OTPVerifyView` when `pendingVerifyEmail != nil`, otherwise
  `EmailOTPAuthView`. This whole flow is only shown while
  `AuthStateManager.phase == .unauthenticated`.
- `onOTPSent` carries `(email, fullName?)`. `EmailOTPAuthViewModel` builds `fullName` by
  joining the non-empty trimmed first/last name with a space; if the result is empty it
  passes `nil`. `RootView` stores that name in `pendingUserName` and forwards it to
  `didAuthenticate(name:)` after verification.
- `EmailOTPAuthView` has an intent segmented picker (`.signup` / `.login`). First/last name
  fields are only shown for `.signup`, and the view passes `nil` for both names when the
  intent is `.login`. The email is trimmed of whitespace/newlines in the ViewModel before the
  request; the send button is disabled while `email` is empty.
- `OTPVerifyView` shows the destination email in its subtitle, has a numeric code field
  (verify button disabled while `otpCode` is empty), and an optional "change email" button.
  Tapping it clears `pendingVerifyEmail` and `pendingUserName`, returning to the email screen.
- Both views disable interaction while `viewModel.state == .loading` and render an inline
  error banner when `state == .error(message)`. ViewModel state is `ViewState<Bool>`
  (`.idle` / `.loading` / `.loaded(true)` / `.error(message)`).

## Error Handling

`AuthError` is the only error type exposed beyond the repository layer; `HTTPClientError`
is never surfaced past `AuthRepository`. Cases:

```
validationFailed, emailAlreadyRegistered, emailNotRegistered, otpInvalid, tokenExpired,
rateLimitExceeded, noPendingDeletionRequest, deletionRequestExpired, deletionFailed,
network, emptyResponse, unknown
```

Each repository method wraps its call in a `do/catch` with the same prelude:

- `CancellationError` and `URLError(.cancelled)` are rethrown as `CancellationError`
  (never converted to an `AuthError`).
- An already-`AuthError` is rethrown unchanged.
- An `HTTPClientError` is routed through that operation's static mapper.
- Any other error becomes `.unknown`.

For methods that return a value (`sendOTP`, `verifyOTP`, `requestAccountDeletion`), the
repository also guards `let envelope, envelope.success, envelope.data != nil` before calling
`envelope.toModel()`, throwing `.emptyResponse` otherwise. `logout` and
`confirmAccountDeletion` return `Void` and **discard** the envelope (no `success`/`data`
guard, so they never throw `.emptyResponse`).

`HTTPClient` surfaces dedicated cases for 401 (`.unauthorized`), 404 (`.notFound`), and
500+ (`.serverError(statusCode:)`); other 4xx arrive as `.clientError(statusCode:data:)`.
Granular 4xx bodies are inspected via `APIErrorParser.code(from:)`, which decodes
`{ error: { code } }` into an `APIErrorCode`.

Mapping per operation (derived from `AuthRepository.map*Error`):

| Case | Trigger |
|---|---|
| `.emailAlreadyRegistered` | 409 `.clientError` on OTP send |
| `.emailNotRegistered` | `.notFound` (404) on OTP send |
| `.validationFailed` | any other `.clientError` on OTP send — both the matched codes (`INVALID_INTENT`, `MISSING_FIELDS`, `SIGNUP_METADATA_REQUIRED`) and the `default:` fall-through map here |
| `.otpInvalid` | any non-429 `.clientError` on verify |
| `.deletionRequestExpired` | 410 `.clientError` on delete confirm, or `REQUEST_EXPIRED` code on another `.clientError` |
| `.deletionFailed` | 500 `.serverError` on delete confirm |
| `.noPendingDeletionRequest` | other `.clientError` on delete confirm — `NO_PENDING_REQUEST` and the `default:` fall-through both map here |
| `.tokenExpired` | `.unauthorized` (401) on OTP send, verify, logout, or any deletion call |
| `.rateLimitExceeded` | 429 `.clientError` on OTP send, verify, logout, delete-request, or delete-confirm |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` on any operation |
| `.emptyResponse` | for value-returning calls only: nil envelope, `success == false`, or `data == nil` |
| `.unknown` | every other `HTTPClientError` (the mapper `default:`) and every non-HTTP, non-cancellation error |

Notes on per-operation mappers:

- `mapOTPError` handles 409, `.notFound`, 429, generic `.clientError` (→ `.validationFailed`),
  `.unauthorized` (→ `.tokenExpired`), and network cases.
- `mapVerifyError` maps 429 → `.rateLimitExceeded`, any other `.clientError` → `.otpInvalid`,
  `.unauthorized` → `.tokenExpired`, and network cases.
- `mapTokenError` (used by `logout` and `requestAccountDeletion`) maps `.unauthorized`
  → `.tokenExpired`, 429 → `.rateLimitExceeded`, and network cases; everything else
  → `.unknown`.
- `mapDeleteConfirmError` handles 410, 500, 429, code-based (`REQUEST_EXPIRED`,
  `NO_PENDING_REQUEST`), `.unauthorized`, and network cases.

ViewModels surface only a subset of cases as localized strings:

- `EmailOTPAuthViewModel.message(for:)` → `.validationFailed` (`auth.error.validation`),
  `.emailAlreadyRegistered` (`auth.error.emailRegistered`), `.emailNotRegistered`
  (`auth.error.emailNotRegistered`), `.network` (`auth.error.network`); all other cases fall
  through to `auth.error.unknown`. A thrown non-`AuthError` also shows `auth.error.unknown`.
- `OTPVerifyViewModel.message(for:)` → `.otpInvalid` (`auth.error.otpInvalid`),
  `.tokenExpired` (`error.tokenExpired`), `.network` (`auth.error.network`); all other cases
  fall through to `auth.error.unknown`.

## Backend Error Codes (from Supabase, for reference)

The shared `APIErrorCode` enum (in `Core/Networking/APIErrorParser.swift`) lists every code
the backend can emit. Auth-relevant codes:

- `MISSING_FIELDS`, `INVALID_INTENT`, `SIGNUP_METADATA_REQUIRED`, `EMAIL_ALREADY_REGISTERED`,
  `EMAIL_NOT_REGISTERED`, `VERIFY_FAILED`, `REFRESH_FAILED`
- `NO_PENDING_REQUEST`, `REQUEST_EXPIRED`, `DELETE_FAILED`
- `RATE_LIMIT_EXCEEDED`, `UNAUTHORIZED`, `MISSING_APIKEY`

Only `INVALID_INTENT`, `MISSING_FIELDS`, `SIGNUP_METADATA_REQUIRED` (OTP send),
`REQUEST_EXPIRED`, and `NO_PENDING_REQUEST` (delete confirm) are matched explicitly by
the Auth mappers; the rest reach an `AuthError` purely via status code or a `default:` branch.

## Analytics

- No analytics events defined for this scope.

## DTOs

All DTOs conform to `ResponseProtocol` and are decoded as the `data` field of an
`APIEnvelope<DTO>`.

- `AuthOTPDataDTO` — `{ id }` → `AuthOTPResultDomain(id:)`
- `AuthSessionDataDTO` — `{ access_token, refresh_token, expires_in }` →
  `AuthSessionDomain(accessToken:refreshToken:expiresIn:)`. Used only by `auth-verify`.
  (The file is named `AuthVerifyDataDTO.swift` but defines `AuthSessionDataDTO`.) There is no
  longer a separate `AuthRefreshDataDTO`; refresh decodes its own private types inside
  `ZomPartAuthTokenProvider`.
- `AuthLogoutDataDTO` — `{ logged_out }` → `Bool`. (Decoded only because it is the envelope's
  `ModelType`; `AuthRepository.logout` ignores the result.)
- `AuthDeleteRequestDataDTO` — `{ expires_in_minutes }` → `AuthDeleteRequestDomain`
- `AuthDeleteConfirmDataDTO` — `{ deleted }` → `Bool`. (Ignored by
  `AuthRepository.confirmAccountDeletion`.)

## Token Refresh

Token refresh lives entirely in `ZomPartAuthTokenProvider.refresh()` and is invoked by
`HTTPClient` (via the `AuthTokenProvider` contract) when a request returns 401:

- It does **not** go through `HTTPClient` or any Auth endpoint/DTO. It builds a `URLRequest`
  directly and POSTs to `\(scheme)://\(SUPABASE_URL)/functions/v1/auth-refresh` with headers
  `Content-Type: application/json` and `apikey: <SUPABASE_PUBLISHABLE_KEY>`, body
  `{ "refresh_token": <current> }`, using an injected `URLSession` (default `.shared`).
- Concurrent 401s are deduplicated: a single in-flight `pendingRefresh` task is created and
  shared under one `OSAllocatedUnfairLock` acquisition, so two 401s can never start two
  refreshes (Supabase rotates the refresh token, so a duplicate request would invalidate the
  session). The task clears `pendingRefresh` in a `defer`, under the same lock.
- The response is decoded into a private `RefreshEnvelope` (`{ success, data }`) /
  `RefreshData` (`{ access_token, refresh_token }`). On a 2xx status with `success == true`
  and non-nil `data`, `updateTokens(accessToken:refreshToken:)` stores and persists the new
  pair, and the original request is retried by `HTTPClient`.
- On any failure (missing refresh token, bad URL, non-2xx status, `success == false`, nil
  data), it calls `clearTokens()`, fires `notifyAuthInvalidated()`, and throws
  `HTTPClientError.unauthorized`.
- `setOnAuthInvalidated(_:)` registers the invalidation callback. `RootView` wires it (once,
  in `.task`) to `AuthStateManager.handleAuthInvalidated()`, hopping to `@MainActor`, which
  resets `phase` to `.unauthenticated` and routes the UI back to the login screen.

## Persistence

- Tokens are persisted in the Keychain via `KeychainTokenStore`, which implements the
  `TokenPersistence` protocol (`save`, `loadAccessToken`, `loadRefreshToken`, `clear`).
- Keychain items use `kSecClassGenericPassword` under service `com.zompart.auth`, with
  accounts `access_token` and `refresh_token`, and accessibility
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. `save` deletes any existing item before
  adding; if `SecItemAdd` fails it deletes and retries once.
- On `init`, `ZomPartAuthTokenProvider` loads stored tokens (only when **both** access and
  refresh are present) and mirrors them into in-memory state under the lock.
- `updateTokens(...)` writes both the in-memory state and the Keychain. `clearTokens()` wipes
  both (used on logout and on refresh failure). `hasStoredTokens` is true when an in-memory
  access token exists.
- `AuthStateManager` detects a fresh install via the UserDefaults flag `app_launched_before`;
  on a fresh install it calls `tokenProvider.clearTokens()` (Keychain entries survive app
  deletion, so this prevents a reinstall from resurrecting stale tokens) and sets the flag.
- `AuthStateManager` also persists `user_email` and `user_name` in UserDefaults
  (`didAuthenticate`), and clears them on `logout` / `handleAuthInvalidated`. The initial
  `phase` is `.onboarding` (if onboarding is enabled and not completed), else `.authenticated`
  (if `hasStoredTokens`), else `.unauthenticated`.

## Open Questions / TODO

- Add account deletion UI screens. `requestAccountDeletion` / `confirmAccountDeletion` exist
  on the repository, but no SwiftUI screens or ViewModels are wired to them yet.
