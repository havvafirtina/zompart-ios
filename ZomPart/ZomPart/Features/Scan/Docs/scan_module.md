# Scan Module

## Responsibilities

- Create or resume a part-identification scan session via `scan-start`.
- Obtain signed upload URLs for photos via `scan-upload-url` (PHOTO scans only).
- Trigger AI/OCR processing via `scan-process`.
- Resolve part ambiguity by selecting a candidate via `scan-feedback` (SELECT_PART).
- Delete a scan and its storage artifacts via `scan-delete`.

## Public Contracts

- Domain Interfaces:
  - `ScanRepositoryProtocol`

## Data Dependencies

| Endpoint | Path | Method |
|---|---|---|
| `scan-start` | `/functions/v1/scan-start` | POST |
| `scan-upload-url` | `/functions/v1/scan-upload-url` | POST |
| `scan-process` | `/functions/v1/scan-process` | POST |
| `scan-feedback` | `/functions/v1/scan-feedback` | POST |
| `scan-delete` | `/functions/v1/scan-delete` | POST |

## Domain Models

- `ScanDomain` — scanId, state, createdAt
- `ScanStateDomain` — `.inputCollected` | `.disambiguation` | `.offersReady` | `.failed`
- `ScanInputTypeDomain` — `.photo` | `.text`
- `ScanNextActionDomain` — `.showOffers` | `.showAlternatives` | `.manualSearch` | `.processScan`
- `ScanProcessResultDomain` — enum: `.offersReady(part)` | `.disambiguation(alternatives, questions)` | `.failed(reason)`
- `ScanPartSummaryDomain` — id, name, partNumber, thumbnailUrl
- `ScanAlternativeDomain` — name, partNumber, confidence
- `ScanQuestionDomain` — id, question, options
- `ScanUploadUrlItemDomain` — photoId, uploadUrl, storagePath, expiresIn
- `ScanFeedbackResultDomain` — scanId, state, nextAction

## Scan Flow

```
startScan(vehicleId:, inputType: .photo)  → ScanDomain (state: INPUT_COLLECTED)
  ↓
getUploadURLs(scanId:, contentTypes:)     → [ScanUploadUrlItemDomain]
  ↓ (client PUTs photo to each uploadUrl)
processScan(scanId:)
  ↓
  ├─ .offersReady(part)                  → show Offers module
  ├─ .disambiguation(alternatives, qs)   → show selection UI
  │     ↓ selectPart(scanId:, partCandidateId:) → ScanFeedbackResultDomain
  │     └─ state: OFFERS_READY           → show Offers module
  └─ .failed(reason)                     → show error / manual search
```

TEXT flow skips `getUploadURLs`; `input_text` is passed in `startScan`.

## Feedback Actions

Only `SELECT_PART` is production-ready. `ANSWER_QUESTION`, `WRONG_RESULT`, and
`MANUAL_SEARCH` exist as backend stubs and are **not exposed** in the iOS protocol.

## Error Handling

`ScanError` maps `HTTPClientError` cases per endpoint context. `HTTPClient` uses dedicated cases
for 404 (`.notFound`) and 429 (`.clientError(statusCode: 429)`).
Repositories also validate `envelope.success` and `envelope.data != nil` before calling `toModel()`.

| Case | Trigger |
|---|---|
| `.invalidUUID` | 400 — missing/invalid UUID |
| `.vehicleNotFound` | 404 (`.notFound`) on scan-start |
| `.scanNotFound` | 404 (`.notFound`) on all other endpoints |
| `.invalidScanType` | 400 — upload on TEXT scan |
| `.invalidMimeType` | 400 — unsupported content_type |
| `.photoLimitReached` | 400 — > 8 photos |
| `.noPhotosUploaded` | 400 — PHOTO scan with no artifacts |
| `.invalidState` | 400 — wrong state for operation |
| `.invalidPart` | 400 — partCandidateId not in scan |
| `.invalidAction` | 400 — unknown feedback action |
| `.conflict` | 409 — concurrent processing |
| `.rateLimitExceeded` | 429 |
| `.network` | No connectivity |
| `.emptyResponse` | Nil envelope or `success: false` |
| `.unknown` | All other errors |

## Constraints

- Max 8 photos per scan (validated server-side atomically).
- Signed upload URLs expire in 60 seconds.
- `start_over: true` irreversibly deletes the pending scan.
- `scan-delete` removes all DB rows and storage files; subsequent calls return 404.

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; scan state is server-side.
- Upload URLs are single-use; clients must not cache them.

## Open Questions / TODO

- Implement `ANSWER_QUESTION` feedback once backend is production-ready.
- Add scan history retrieval (scan-get) when History module is built.
- Parse error response bodies for granular 400 distinction once SBNetworking supports it.
