# Scan Module

## Responsibilities

- Create or resume a part-identification scan session via `scan-start`.
- Obtain signed upload URLs for photos via `scan-upload-url`, then PUT each photo to its URL (PHOTO scans only).
- Trigger AI/OCR processing via `scan-process` (180-second client timeout).
- Resolve part ambiguity by selecting a candidate via `scan-feedback` (SELECT_PART only).

`scan-get` (single scan + history) belongs to the History module and `scan-offers` to the Offer module — neither is defined here. There is no scan-delete endpoint in this module.

## Public Contracts

- Domain Interfaces:
  - `ScanRepositoryProtocol`
- Module factory: `ScanModule` (enum) — `makeScanRepository`, `makeScanHomeViewModel`, `makeScanInputViewModel`, `makeScanProcessingViewModel`, `makeDisambiguationViewModel`.

`ScanRepositoryProtocol` methods:

```
func startScan(vehicleId: String, inputType: ScanInputTypeDomain, userDescription: String?, ocrTexts: [String], startOver: Bool) async throws -> ScanDomain
func getUploadURLs(scanId: String, contentTypes: [String]) async throws -> [ScanUploadUrlItemDomain]
func uploadPhotos(scanId: String, photosData: [Data], onPhotoUploaded: (@Sendable @MainActor (Int) -> Void)?) async throws
func processScan(scanId: String) async throws -> ScanProcessResultDomain
func selectPart(scanId: String, partCandidateId: String) async throws -> ScanFeedbackResultDomain
```

The protocol is `Sendable`; the concrete `ScanRepository` is an `actor`.

## Data Dependencies

| Endpoint | Path | Method | Response Envelope | Payload (snake_case) |
|---|---|---|---|---|
| `ScanStartEndpoint` | `/functions/v1/scan-start` | POST | `APIEnvelope<ScanStartDataDTO>` | `vehicle_id`, `input_type`, `user_description?`, `ocr_texts`, `start_over` |
| `ScanUploadUrlEndpoint` | `/functions/v1/scan-upload-url` | POST | `APIEnvelope<ScanUploadUrlDataDTO>` | `scan_id`, `files[].content_type` |
| `ScanProcessEndpoint` | `/functions/v1/scan-process` | POST | `APIEnvelope<ScanProcessDataDTO>` | `scan_id` (timeoutInterval = 180) |
| `ScanFeedbackEndpoint` | `/functions/v1/scan-feedback` | POST | `APIEnvelope<ScanFeedbackDataDTO>` | `scan_id`, `action = "SELECT_PART"`, `selected_part_id` |

- `scan-feedback` only ever sends `action: "SELECT_PART"`; `selected_part_id` carries the `part_candidates.id` UUID.
- `scan-process` is the only endpoint that overrides `timeoutInterval` (180s); the others use the client default.

Photo PUTs use a plain `URLSession.shared.upload` to the signed URL (not `HTTPClient`); the host/scheme are rewritten from plist values (`SUPABASE_API_SCHEME`, `SUPABASE_URL`) via `fixUploadUrl`. A non-2xx HTTP response (e.g. a 403 from an expired signed URL) is treated as a failed upload, not a success.

## Domain Models

- `ScanDomain` (Equatable, Sendable) — `scanId`, `state: ScanStateDomain`, `createdAt: String`.
- `ScanStateDomain` (String enum) — `.inputCollected` (INPUT_COLLECTED) | `.disambiguation` (DISAMBIGUATION) | `.offersReady` (OFFERS_READY) | `.failed` (FAILED).
- `ScanInputTypeDomain` (Encodable wire enum) — `.photo` (PHOTO) | `.text` (TEXT).
- `ScanInputMode` (UI-only, Equatable, Sendable) — `.photo` | `.text`; `asNetworkType` maps 1:1 to `ScanInputTypeDomain`. Locks `ScanInputView` behavior at entry so the chosen mode (not the on-screen content) decides `input_type`.
- `ScanNextActionDomain` (String enum) — `.showOffers` (SHOW_OFFERS) | `.showAlternatives` (SHOW_ALTERNATIVES) | `.manualSearch` (MANUAL_SEARCH) | `.processScan` (PROCESS_SCAN).
- `ScanProcessResultDomain` (Equatable, Sendable) — `.offersReady(scanId:, part:)` | `.disambiguation(scanId:, alternatives:, questions:)` | `.failed(scanId:, reason:)`.
- `ScanPartSummaryDomain` (Equatable, Hashable, Sendable) — `id`, `name`, `nameTr?`, `nameSv?`, `partNumber`, `thumbnailUrl?`, plus Layer-1 canonical enrichment (all optional): `oemNumber`, `mpn`, `ean`, `brand`, `manufacturer`, `crossReferences`, `categoryTecdoc`, `vehicleCompatible`, `imageUrl`, `confidenceScore`. Computed: `localizedName` (locale-aware: tr → `nameTr`, sv → `nameSv`, else `name`), `displayImageUrl` (`imageUrl ?? thumbnailUrl`).
- `ScanAlternativeDomain` (Equatable, Hashable, Sendable) — `name`, `id` (`part_candidates.id` UUID; decoded from wire key `part_number`), `confidence: Double`.
- `ScanQuestionDomain` (Equatable, Hashable, Sendable) — `id` (stable; synthesized from `UUID()` when the wire `id` is nil), `question`, `options: [String]`.
- `ScanUploadUrlItemDomain` (Equatable, Sendable) — `photoId`, `uploadUrl`, `storagePath`, `expiresIn` (signed-URL validity in seconds, typically 60).
- `ScanFeedbackResultDomain` (Equatable, Sendable) — `scanId`, `state: ScanStateDomain`, `nextAction: ScanNextActionDomain`.

## DTO → Domain Mappings

| DTO | Wire keys → fields | toModel() |
|---|---|---|
| `ScanStartDataDTO` | `scan_id`, `state`, `created_at` | `ScanDomain`; `state` parsed via `ScanStateDomain(rawValue:)`, falling back to `.inputCollected`. |
| `ScanUploadUrlItemDTO` | `photo_id`, `upload_url`, `storage_path`, `expires_in` | `ScanUploadUrlItemDomain`. |
| `ScanUploadUrlDataDTO` | `items: [ScanUploadUrlItemDTO]` | `[ScanUploadUrlItemDomain]` (maps each item). |
| `ScanPartSummaryDTO` | `id`, `name`, `name_tr`, `name_sv`, `part_number`, `thumbnail_url`, `oem_number`, `mpn`, `ean`, `brand`, `manufacturer`, `cross_references`, `category_tecdoc`, `vehicle_compatible`, `image_url`, `confidence_score` | `ScanPartSummaryDomain`. |
| `ScanAlternativeDTO` | `name`, `confidence`, `id` ← wire key `part_number` | `ScanAlternativeDomain`. |
| `ScanQuestionDTO` | `id?`, `question`, `options` | `ScanQuestionDomain`; nil `id` becomes a synthesized `UUID().uuidString` (held in a private `stableId`). |
| `ScanProcessDataDTO` | `scan_id`, `state`, `next_action`, `part?`, `alternatives?`, `questions?`, `reason?` | branches on `state` (see below). |
| `ScanFeedbackDataDTO` | `scan_id`, `state`, `next_action` | `ScanFeedbackResultDomain`; `state` falls back to `.offersReady`, `nextAction` to `.showOffers`. |

`ScanProcessDataDTO.toModel()` branch logic:

```
state == OFFERS_READY:
    part present  → .offersReady(scanId:, part:)
    part missing  → .failed(scanId:, reason: "missing_part")
state == DISAMBIGUATION:
    → .disambiguation(scanId:, alternatives ?? [], questions ?? [])
default (incl. FAILED / INPUT_COLLECTED / unknown):
    → .failed(scanId:, reason: reason ?? "unknown")
```

## Scan Flow

```
ScanHome
  ├─ "Scan with photo" → scanInputPhoto(vehicleId)  (mode .photo)
  └─ "Scan with text"  → scanInputText(vehicleId)   (mode .text)

ScanInput (analyze)
  startScan(vehicleId:, inputType:, userDescription:, ocrTexts:, startOver: false) → ScanDomain
    ↓ (.photo mode only, when photos exist)
  uploadPhotos(scanId:, photosData:, onPhotoUploaded:) → getUploadURLs + per-photo PUT
    ↓ onScanCreated(scan)
  scanProcessing(scanId)

ScanProcessing
  processScan(scanId:) → ScanProcessResultDomain (handleProcessResult routes the rest)
    ├─ .offersReady(scanId:, part:)        → scanResult(scanId:, part:)
    ├─ .disambiguation(scanId:, alts, qs)  → disambiguation(scanId:, alts, qs)
    └─ .failed(scanId:, reason:)           → scanFailed(scanId:, reason:)

ScanResult       → "View offers" → offers(scanId:)   |  "Go home" → resetScanFlow()
Disambiguation   → selectPart(scanId:, partCandidateId:) → ScanFeedbackResultDomain
                     nextAction == .showOffers → offers(scanId:)
ScanFailed       → Retry (pop back to scanInput*) | Search by text | Go home
```

### Navigation wiring (MainTabView / AppRouter)

`AppRouter.ScanRoute` cases relevant to this module: `scanInputPhoto(vehicleId:)`, `scanInputText(vehicleId:)`, `scanProcessing(scanId:)`, `disambiguation(scanId:, alternatives:, questions:)`, `scanResult(scanId:, part:)`, `scanFailed(scanId:, reason:)`, `offers(scanId:)`, `history`, `scanDetail(scanId:)`. (The last three are owned by Offer/History; the Scan flow only pushes into them.)

`handleProcessResult(_:)`:

- Calls `vmCache.invalidateHistory()` and `vmCache.invalidateScanProcessing()` first.
- Finds the last `scanProcessing` route in `scanPath` and `replaceSubrange(idx..., with: [resultRoute])`, so the processing screen is dropped (no back-button into it). If no processing route is found it appends instead.
- `.offersReady` → `scanResult`, `.disambiguation` → `disambiguation`, `.failed` → `scanFailed`.

`ScanProcessingView.onCancel` and the processing/result/failed "Go home" buttons call `router.resetScanFlow()` (clears `scanPath`). Clearing `scanPath` triggers `vmCache.invalidateScanFlow()`, evicting the cached scan-input, scan-processing, and disambiguation view models.

`ScanFailedView`:

- Retry: pops routes off `scanPath` until a `scanInputPhoto`/`scanInputText` route is on top (returns the user to the input screen to adjust and re-analyze).
- Search by text: finds the originating `vehicleId` from the path and resets `scanPath` to `[scanInputText(vehicleId:)]`; if none is found, clears the path.
- Go home: `resetScanFlow()`.

`DisambiguationView` on resolve calls `vmCache.invalidateScanDetail(scanId:)` (so the detail/offers VMs reload with the chosen part), then pushes `offers(scanId:)` when `nextAction == .showOffers`.

## Backend Scan State Machine (as handled by the app)

The app drives and reacts to the backend scan state machine through `scan-start`, `scan-process`, and `scan-feedback`:

- `scan-start` returns `INPUT_COLLECTED` for a new/resumed pending scan. If it resumes a scan already in `DISAMBIGUATION` or `OFFERS_READY`, `ScanInputViewModel` re-calls `startScan(startOver: true)` because a finished scan can take neither new photos nor another process call.
- `scan-process` advances `INPUT_COLLECTED` to one of `OFFERS_READY` (confident match), `DISAMBIGUATION` (ambiguous — alternatives and/or clarifying questions), or `FAILED` (no usable result). The app maps these via `ScanProcessResultDomain`.
- `scan-feedback` (SELECT_PART) advances `DISAMBIGUATION` to `OFFERS_READY` with `next_action = SHOW_OFFERS`.

## Photo Capture / Upload Pipeline (PHOTO mode)

1. Capture/select photos:
   - `ScanCameraView` (full-screen cover) drives `DataScannerViewController` via `ScanCameraRepresentable`/`ScanCameraCoordinator`. It guards on `AVCaptureDevice` authorization (`.authorized` → scanner, `.notDetermined` → requests access, otherwise a permission-denied view with an Open Settings button). Live-text tap recognition forwards text via `onTextRecognized`; tap-highlights are managed as overlay `UIView`s. Capture uses `coordinator.capturePhoto()` and respects `remainingSlots = maxPhotos - currentPhotoCount - capturedPhotos.count` (the capture button hides at 0). The scanner is only shown when `LiveTextScannerView.isDeviceSupported` (`DataScannerViewController.isSupported`).
   - Gallery: `PhotosPicker` loads a `UIImage`, adds it, then opens `PhotoTextPickerView` for OCR on that image.
   - `PhotoTextPickerView` runs Vision `VNRecognizeTextRequest` (`.accurate`, language correction on) on the image, overlays tappable bounding boxes, and supports pinch-to-zoom (1.0–5.0), pan when zoomed, and double-tap zoom (stroke widths scale by `1/scale` so they stay constant on screen). Selected texts are returned via `onTextsSelected` and added as OCR chips.
2. `ScanInputViewModel.addPhoto` appends only while `photos.count < 8`. OCR strings are deduplicated and trimmed before being added to `ocrTexts`.
3. On analyze, photos are resized to a 1024px long edge (`UIImage.resizedToLongEdge`, which returns the original if already smaller and renders at scale 1) and JPEG-encoded at quality 0.8. Each becomes one `image/jpeg` content type.
4. `getUploadURLs(scanId:, contentTypes:)` returns one signed URL per content type. `uploadPhotos` rewrites each URL's scheme/host via `fixUploadUrl`, PUTs the JPEG with `Content-Type: image/jpeg`, and calls `onPhotoUploaded(index + 1)` on the main actor after each successful PUT. The view model uses this to drive `uploadedCount` and `uploadProgress = uploaded / total`, shown as a determinate `ProgressView` plus an "uploading X/Y" label.
5. Cancellation: `Task.checkCancellation()` runs before each PUT; `CancellationError` and `URLError.cancelled` propagate as cancellation (the screen resets to `.idle`).

`ScanInputViewModel` resilience:

- `onAnalyzeTapped` cancels any prior analyze task and starts a fresh one. `onDisappear` cancels the in-flight analyze so a finished upload can't yank the user into the flow from another tab.
- If `startScan` resumes a pending scan in `DISAMBIGUATION`/`OFFERS_READY`, it immediately re-runs with `startOver: true`.
- If upload fails with `ScanError.photoLimitReached` (the resumed pending scan already holds the photo quota), it retries the whole flow once with `startOver: true` (`analyzeStartingOver`).
- The text query (`inputText`, trimmed) is sent as `user_description` in both photo and text modes; in text mode it is the required input, in photo mode it is an optional clarifier.

## Disambiguation / Feedback (SELECT_PART) Path

- `DisambiguationView` renders optional clarifying `questions` (read-only — question text plus bulleted options) and a list of `alternatives` (name + `confidence` shown as a percentage).
- Tapping an alternative calls `DisambiguationViewModel.selectPart(partCandidateId:)`, which calls `scanRepository.selectPart(scanId:, partCandidateId:)`. The candidate id is the `ScanAlternativeDomain.id` (decoded from the wire `part_number`).
- The view disables interaction and shows a spinner while `.loading`; on success it forwards the `ScanFeedbackResultDomain` via `onResolved`.
- Only `SELECT_PART` is exposed (`selectPart`). `ANSWER_QUESTION`, `WRONG_RESULT`, and `MANUAL_SEARCH` remain backend stubs and are not surfaced.

## ScanResult / ScanProcessing / ScanFailed screens

- `ScanProcessingView`: indeterminate spinner, rotating tips (`processingTip1…4`, cycled every 3s while `.loading`). Shows a Cancel button while loading (leaving keeps the scan pending server-side, resumable later). On error it shows the message plus Retry (`startProcessing`) and Go home. `startProcessing` is idempotent — it no-ops if already `.loading` or `.loaded`.
- `ScanResultView`: shows the canonical part image via `AsyncImage(part.displayImageUrl)` (falling back to a generic `checkmark.seal.fill` on empty/failure or when no URL), `part.localizedName`, `part.partNumber`, and a "manufacturer · brand" badge when both are present. When `part.vehicleCompatible == false` it shows a compatibility warning. Buttons: View offers → `offers`, Go home → `resetScanFlow`.
- `ScanFailedView`: warning icon, title/subtitle, the raw `reason` (when non-empty), and Retry / Search by text / Go home buttons (wired in `MainTabView` as described above).

## Error Handling

Each repository method wraps its call in `do/catch` and maps `HTTPClientError` through a dedicated mapper (`mapStartError`, `mapUploadError`, `mapProcessError`, `mapFeedbackError`). All four guard `envelope != nil`, `envelope.success`, and `envelope.data != nil` before `toModel()`, throwing `.emptyResponse` otherwise. `CancellationError` and `URLError.cancelled` are re-thrown as `CancellationError`; already-typed `ScanError` re-throws unchanged; any other error becomes `.unknown`. `ScanError` is the only error type that leaves the repository. 4xx bodies are decoded by `APIErrorParser.code(from:)` (`{ error: { code } }`).

| Case | Trigger |
|---|---|
| `.invalidUUID` | `INVALID_UUID` code on start/upload/process/feedback |
| `.vehicleNotFound` | 404 (`.notFound`) on scan-start |
| `.scanNotFound` | 404 (`.notFound`) on upload/process/feedback |
| `.invalidScanType` | `INVALID_SCAN_TYPE` on upload |
| `.invalidMimeType` | `INVALID_MIME_TYPE` on upload |
| `.photoLimitReached` | `PHOTO_LIMIT_REACHED` on upload |
| `.photoUploadFailed` | Signed-URL PUT returned non-2xx (e.g. expired-URL 403), or a malformed upload URL was received (raised in `uploadPhotos`, not from a mapper) |
| `.noPhotosUploaded` | `NO_PHOTOS_UPLOADED` on process |
| `.invalidState` | `INVALID_STATE` on process/feedback |
| `.invalidPart` | `INVALID_PART` on feedback |
| `.invalidAction` | `INVALID_ACTION` on feedback |
| `.conflict` | 409 on process (concurrent processing) |
| `.aiTemporarilyUnavailable` | 5xx (`.serverError`) on process — both AI providers (Gemini + OpenAI fallback) down |
| `.tokenExpired` | 401 (`.unauthorized`) after refresh failure |
| `.rateLimitExceeded` | 429 (`clientError(statusCode: 429, _)`) on start/upload/process/feedback |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` (also caught directly in `uploadPhotos`) |
| `.emptyResponse` | Nil envelope, `success: false`, or nil `data` |
| `.unknown` | Any unmapped code (mapper `default:`) or any other error |

`ScanError.localizedMessage` (defined in `ScanModule.swift`) maps `.network`, `.tokenExpired`, `.rateLimitExceeded`, `.scanNotFound`, `.vehicleNotFound`, `.invalidState`, `.conflict`, `.noPhotosUploaded`, `.photoLimitReached`, `.photoUploadFailed`, and `.aiTemporarilyUnavailable` to dedicated `Localized.Error.*` strings; everything else (incl. `.invalidUUID`, `.invalidScanType`, `.invalidMimeType`, `.invalidPart`, `.invalidAction`, `.emptyResponse`, `.unknown`) falls through to `Localized.Error.unknown`.

`APIErrorCode` lists every code the backend can emit; codes with no explicit repository mapping fall through each mapper's `default:` to `.unknown`. This keeps the wire contract documented without forcing a mapping for every code.

## Constraints

- Max 8 photos per scan, enforced client-side (`addPhoto` guard at `< 8`, camera `maxPhotos: 8` and `remainingSlots`) and server-side (`PHOTO_LIMIT_REACHED`).
- Photos are resized to a 1024px long edge and JPEG-encoded (quality 0.8) before upload; content type is always `image/jpeg`.
- Signed upload URLs are single-use and short-lived (`expiresIn`, typically 60s) — never cached; an expired URL surfaces as `.photoUploadFailed`.
- `start_over: true` deletes the pending scan and starts fresh. `ScanInputViewModel` normally sends `false`, escalating to `true` only when resuming a non-pending scan or recovering from `PHOTO_LIMIT_REACHED`.
- `input_type` is locked to the entry `ScanInputMode` and is not re-derived from on-screen content at submit time.

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; scan state is server-side.
- Vehicle deletions are tracked client-side via the `deleted_vehicle_ids` UserDefaults key, filtered out in `ScanHomeViewModel.loadVehicles()`.
- View models are cached/evicted by `ViewModelCache` (scan-input keyed by `mode+vehicleId`, scan-processing/disambiguation keyed by `scanId`, scan-home a singleton).

## Open Questions / TODO

- Expose additional feedback actions (`ANSWER_QUESTION`, `WRONG_RESULT`, `MANUAL_SEARCH`) once the backend ships them as production-ready.
