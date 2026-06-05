# Scan Module

## Responsibilities

- Create or resume a part-identification scan session via `scan-start`.
- Obtain signed upload URLs for photos via `scan-upload-url`, then PUT each photo to its URL (PHOTO scans only).
- Trigger AI/OCR processing via `scan-process` (3-minute client timeout).
- Resolve part ambiguity by selecting a candidate via `scan-feedback` (SELECT_PART only).
- Delete a scan and its storage artifacts via `scan-delete`.

`scan-get` (single scan + history) belongs to the History module and `scan-offers` to the Offer module — neither is defined here.

## Public Contracts

- Domain Interfaces:
  - `ScanRepositoryProtocol`

## Data Dependencies

| Endpoint | Path | Method | Response Envelope | Payload (snake_case) |
|---|---|---|---|---|
| `ScanStartEndpoint` | `/functions/v1/scan-start` | POST | `APIEnvelope<ScanStartDataDTO>` | `vehicle_id`, `input_type`, `user_description?`, `ocr_texts`, `start_over` |
| `ScanUploadUrlEndpoint` | `/functions/v1/scan-upload-url` | POST | `APIEnvelope<ScanUploadUrlDataDTO>` | `scan_id`, `files[].content_type` |
| `ScanProcessEndpoint` | `/functions/v1/scan-process` | POST | `APIEnvelope<ScanProcessDataDTO>` | `scan_id` (timeoutInterval = 180) |
| `ScanFeedbackEndpoint` | `/functions/v1/scan-feedback` | POST | `APIEnvelope<ScanFeedbackDataDTO>` | `scan_id`, `action = "SELECT_PART"`, `selected_part_id` |
| `ScanDeleteEndpoint` | `/functions/v1/scan-delete` | POST | `APIEnvelope<ScanDeleteDataDTO>` | `scan_id` |

Photo PUTs use a plain `URLSession.shared.upload` to the signed URL (not `HTTPClient`); the host/scheme are rewritten from plist values via `fixUploadUrl`.

## Domain Models

- `ScanDomain` — scanId, state, createdAt
- `ScanStateDomain` — `.inputCollected` (INPUT_COLLECTED) | `.disambiguation` (DISAMBIGUATION) | `.offersReady` (OFFERS_READY) | `.failed` (FAILED)
- `ScanInputTypeDomain` (Encodable wire enum) — `.photo` (PHOTO) | `.text` (TEXT)
- `ScanInputMode` (UI-only) — `.photo` | `.text`; `asNetworkType` maps 1:1 to `ScanInputTypeDomain`. Locks `ScanInputView` behavior at entry.
- `ScanNextActionDomain` — `.showOffers` | `.showAlternatives` | `.manualSearch` | `.processScan`
- `ScanProcessResultDomain` — `.offersReady(scanId:, part:)` | `.disambiguation(scanId:, alternatives:, questions:)` | `.failed(scanId:, reason:)`
- `ScanPartSummaryDomain` (Hashable) — id, name, nameTr?, nameSv?, partNumber, thumbnailUrl?, plus Layer-1 canonical enrichment (all optional): oemNumber, mpn, ean, brand, manufacturer, crossReferences, categoryTecdoc, vehicleCompatible, imageUrl, confidenceScore. Computed: `localizedName` (locale-aware), `displayImageUrl` (imageUrl ?? thumbnailUrl).
- `ScanAlternativeDomain` (Hashable) — name, `id` (part_candidates.id UUID; decoded from wire key `part_number`), confidence
- `ScanQuestionDomain` (Hashable) — id (stable; synthesized when wire id is nil), question, options
- `ScanUploadUrlItemDomain` — photoId, uploadUrl, storagePath, expiresIn
- `ScanFeedbackResultDomain` — scanId, state, nextAction

## Scan Flow

```
startScan(vehicleId:, inputType:, userDescription:, ocrTexts:, startOver:) → ScanDomain (INPUT_COLLECTED)
  ↓ (.photo mode only, when photos exist)
uploadPhotos(scanId:, photosData:, onPhotoUploaded:)   → getUploadURLs + per-photo PUT
  ↓
processScan(scanId:)                                   → ScanProcessResultDomain
  ├─ .offersReady(scanId:, part:)        → ScanResultView → Offers module
  ├─ .disambiguation(scanId:, alts, qs)  → DisambiguationView
  │     ↓ selectPart(scanId:, partCandidateId:) → ScanFeedbackResultDomain
  │     └─ nextAction == .showOffers     → Offers module
  └─ .failed(scanId:, reason:)           → ScanFailedView (retry / text search / home)
```

`MainTabView.handleProcessResult` calls `vmCache.invalidateHistory()`, then replaces the `.scanProcessing` route with the result route. TEXT flow skips upload; the text query is sent as `user_description` in `startScan`. ScanHome → ScanInput (photo or text) → ScanProcessing → result branch.

## Feedback Actions

Only `SELECT_PART` is exposed in the iOS protocol (`selectPart`). `ANSWER_QUESTION`, `WRONG_RESULT`, and `MANUAL_SEARCH` remain backend stubs and are not surfaced.

## Error Handling

Each endpoint has its own `HTTPClientError → ScanError` mapper (start/upload/process/feedback/common). Repositories also validate `envelope != nil`, `envelope.success`, and `envelope.data != nil` before `toModel()`. `ScanError` is the only error type that leaves the repository.

| Case | Trigger |
|---|---|
| `.invalidUUID` | `INVALID_UUID` code, or default for start/common 4xx |
| `.vehicleNotFound` | 404 (`.notFound`) on scan-start |
| `.scanNotFound` | 404 (`.notFound`) on upload/process/feedback/delete |
| `.invalidScanType` | `INVALID_SCAN_TYPE` (default for upload 4xx) |
| `.invalidMimeType` | `INVALID_MIME_TYPE` on upload |
| `.photoLimitReached` | `PHOTO_LIMIT_REACHED` on upload |
| `.noPhotosUploaded` | `NO_PHOTOS_UPLOADED` on process |
| `.invalidState` | `INVALID_STATE` (default for process/feedback 4xx) |
| `.invalidPart` | `INVALID_PART` on feedback |
| `.invalidAction` | `INVALID_ACTION` on feedback |
| `.conflict` | 409 on process (concurrent processing) |
| `.aiTemporarilyUnavailable` | 5xx (`.serverError`) on process — both AI providers down |
| `.tokenExpired` | 401 (`.unauthorized`) after refresh failure |
| `.rateLimitExceeded` | 429 |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` |
| `.emptyResponse` | Nil envelope, `success: false`, or nil `data` |
| `.unknown` | All other errors |

## Constraints

- Max 8 photos per scan, enforced client-side (`addPhoto` guard, camera `maxPhotos: 8`) and server-side.
- Photos are resized to a 1024px long edge and JPEG-encoded (quality 0.8) before upload; content type is always `image/jpeg`.
- Signed upload URLs are single-use and short-lived (`expiresIn`, typically 60s) — never cache them.
- `startOver: true` deletes the pending scan and starts fresh (`ScanInputViewModel` always sends `false`).
- `scan-delete` removes DB rows and storage files; subsequent calls return 404 → `.scanNotFound`.

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; scan state is server-side.
- Vehicle deletions are tracked client-side via the `deleted_vehicle_ids` UserDefaults key (filtered in `ScanHomeViewModel`).

## Open Questions / TODO

- Expose additional feedback actions (`ANSWER_QUESTION`, `WRONG_RESULT`, `MANUAL_SEARCH`) once the backend ships them as production-ready.
