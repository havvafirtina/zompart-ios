# Auth Module

## Responsibilities

- Send email OTP for signup or login via `auth-otp`.
- Verify OTP and obtain session tokens via `auth-verify`.
- Refresh expired session tokens via `auth-refresh`.
- Logout with configurable scope via `auth-logout`.
- Initiate and confirm account deletion via `auth-delete-request` / `auth-delete-confirm`.

## Public Contracts

- Domain Interfaces:
  - `AuthRepositoryProtocol`
- Navigation Entry Points:
  - `EmailOTPAuthView` — email input + OTP send (used from composition root)
  - `OTPVerifyView` — 6-digit code entry + verify (presented by composition root after OTP send)

## Data Dependencies

- Endpoints:
  - `AuthOTPEndpoint` — POST `/functions/v1/auth-otp`
  - `AuthVerifyEndpoint` — POST `/functions/v1/auth-verify`
  - `AuthRefreshEndpoint` — POST `/functions/v1/auth-refresh`
  - `AuthLogoutEndpoint` — POST `/functions/v1/auth-logout`
  - `AuthDeleteRequestEndpoint` — POST `/functions/v1/auth-delete-request`
  - `AuthDeleteConfirmEndpoint` — POST `/functions/v1/auth-delete-confirm`
- Networking:
  - Uses SBNetworking `HTTPClient` with base URL and `apikey` header injected at app level via `ZomPartAuthTokenProvider`.
  - Bearer token automatically added by `ZomPartAuthTokenProvider` for authenticated endpoints.

## Domain Models

- `AuthOTPResultDomain` — OTP send confirmation (`id`)
- `AuthSessionDomain` — `accessToken`, `refreshToken`, `expiresIn`
- `AuthLogoutScope` — `.local` | `.global` | `.others`
- `AuthDeleteRequestDomain` — `expiresInMinutes`

## Auth Flow

```
EmailOTPAuthView → sendOTP() → onOTPSent(email)
  ↓ (composition root navigates)
OTPVerifyView → verifyOTP() → onVerified(AuthSessionDomain)
  ↓ (composition root stores tokens + sets isAuthenticated)
ContentView (main app)
```

## Error Handling

`AuthError` maps `HTTPClientError` by status code:

| Case | Trigger |
|---|---|
| `.validationFailed` | 400 on OTP send |
| `.emailAlreadyRegistered` | 409 on signup |
| `.otpInvalid` | 4xx on verify |
| `.tokenExpired` | 401 on refresh/logout/delete |
| `.noPendingDeletionRequest` | 400 on delete confirm |
| `.deletionRequestExpired` | 410 on delete confirm |
| `.deletionFailed` | 500 on delete confirm |
| `.network` | No connectivity |
| `.emptyResponse` | Nil envelope |
| `.unknown` | All other errors |

> **Note:** Detailed error-code parsing from the response body is not yet supported
> because `HTTPClientError.clientError` does not carry the response data.

## Backend Error Codes (from Supabase, for reference)

- `MISSING_FIELDS`, `INVALID_INTENT`, `SIGNUP_METADATA_REQUIRED`, `EMAIL_ALREADY_REGISTERED`
- `EMAIL_NOT_REGISTERED`, `VERIFY_FAILED`, `REFRESH_FAILED`
- `NO_PENDING_REQUEST`, `REQUEST_EXPIRED`, `DELETE_FAILED`

## Analytics

- No analytics events defined for this scope.

## Persistence

- Tokens are stored in `ZomPartAuthTokenProvider` (in-memory).
- Keychain persistence for tokens is not yet implemented.

## Open Questions / TODO

- Persist tokens in Keychain after successful verification.
- Add account deletion UI screens.
- Parse error response bodies once SBNetworking supports it.
- Add token auto-refresh logic when access token expires during app session.
