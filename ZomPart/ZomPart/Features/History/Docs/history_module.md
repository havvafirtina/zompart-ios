# History Module

## Responsibilities

- Fetch full details of a single scan via `scan-get?scanId={uuid}`.
- Fetch a paginated list of the user's scans via `scan-get?action=history`, optionally filtered by `vehicle_id`.

## Public Contracts

- Domain Interfaces:
  - `HistoryRepositoryProtocol`
- Module factory (`HistoryModule`):
  - `makeHistoryRepository(httpClient:) -> HistoryRepositoryProtocol`
  - `makeHistoryListViewModel(env:vehicleId:) -> HistoryListViewModel` (`vehicleId` defaults to `nil`)
  - `makeScanDetailViewModel(env:scanId:) -> ScanDetailViewModel`

## Data Dependencies

| Endpoint | Path | Method | Response | Mode |
|---|---|---|---|---|
| `ScanGetSingleEndpoint` | `/functions/v1/scan-get?scanId={uuid}` | GET | `APIEnvelope<ScanDetailDataDTO>` | Single scan |
| `ScanGetHistoryEndpoint` | `/functions/v1/scan-get?action=history` | GET | `APIEnvelope<HistoryListDataDTO>` | Paginated list |

Both endpoints share the path constant `kScanGetPath = "/functions/v1/scan-get"` and differ only by
query parameters. Each `Endpoint` is reached through a matching `RequestProtocol`
(`ScanGetSingleRequest`, `ScanGetHistoryRequest`) that `toEndpoint()` maps to the concrete endpoint.
Both endpoints carry `payload: nil` (no request body).

## Repository Protocol

```swift
func fetchScan(scanId: String) async throws -> ScanDetailDomain
func fetchHistory(vehicleId: String?, limit: Int, offset: Int) async throws -> HistoryPageDomain
```

- `HistoryRepositoryProtocol` is `Sendable`.
- No default-argument overloads: `vehicleId`, `limit`, and `offset` are always passed explicitly by the
  caller. `HistoryListViewModel` uses a private `pageSize = 20` for every request.
- `fetchHistory` returns scans newest-first (ordering is enforced by the backend).

## Query Parameters

### Single mode (`ScanGetSingleEndpoint`)
| Param | Required | Description |
|---|---|---|
| `scanId` | Yes | UUID of the scan |

### History mode (`ScanGetHistoryEndpoint`)
| Param | Required | Default | Description |
|---|---|---|---|
| `action` | Yes | — | Always sent literally as `"history"` |
| `limit` | Yes | — | Page size, always serialized via `String(limit)` (backend defaults to 20, max 50) |
| `offset` | Yes | — | Pagination offset, always serialized via `String(offset)` |
| `vehicle_id` | No | omitted | Filter by vehicle; the key is added only when `vehicleId != nil` |

## Domain Models

### Shared sub-objects (`HistorySharedDomain.swift`)
- `HistoryVehicleSummaryDomain` — `id: String`, `make: String`, `model: String`, `year: Int`. Defined
  independently; History must not import the Vehicle feature.
- `HistoryPartSummaryDomain` — base fields `id: String`, `name: String`, `nameTr: String?`,
  `nameSv: String?`, `partNumber: String`, `thumbnailUrl: String?`; Layer-1 canonical enrichment
  `oemNumber: String?`, `mpn: String?`, `ean: String?`, `brand: String?`, `manufacturer: String?`,
  `crossReferences: [String]?`, `categoryTecdoc: String?`, `vehicleCompatible: Bool?`,
  `imageUrl: String?`, `confidenceScore: Double?`. Computed:
  - `localizedName` — returns `nameTr ?? name` for `tr`, `nameSv ?? name` for `sv`, else `name`
    (driven by `Locale.current.language.languageCode`).
  - `displayImageUrl` — `imageUrl ?? thumbnailUrl`.

  Defined independently; History must not import Scan or Offer. Mirrors `ScanPartSummaryDomain` and
  `OfferPartSummaryDomain`.

### Single scan (`ScanDetailDomain.swift`)
- `ScanDetailDomain` — `scan: ScanDetailItemDomain`, `vehicle: HistoryVehicleSummaryDomain?`,
  `artifacts: [ScanArtifactDomain]`, `selectedPart: HistoryPartSummaryDomain?`.
- `ScanDetailItemDomain` — `id: String`, `state: String`, `inputType: String?`, `inputText: String?`,
  `aiStatus: ScanAiStatusDomain?`, `createdAt: String`, `updatedAt: String`, `vehicleId: String?`.
- `ScanAiStatusDomain` (String enum) — `.confident` (`CONFIDENT`) | `.ambiguous` (`AMBIGUOUS`) |
  `.needsInfo` (`NEEDS_INFO`) | `.failed` (`FAILED`).
- `ScanArtifactDomain` — `id: String`, `artifactType: ScanArtifactTypeDomain?`, `ocrRawText: String?`,
  `thumbnailUrl: String?`.
- `ScanArtifactTypeDomain` (String enum) — `.photo` (`PHOTO`) | `.ocrResult` (`OCR_RESULT`) |
  `.thumbnail` (`THUMBNAIL`) | `.qa` (`QA`).

### History list (`HistoryPageDomain.swift`)
- `HistoryPageDomain` — `scans: [HistoryScanSummaryDomain]`, `pagination: HistoryPaginationDomain`.
- `HistoryScanSummaryDomain` — `id: String`, `state: String`, `createdAt: String`,
  `vehicle: HistoryVehicleSummaryDomain?`, `selectedPart: HistoryPartSummaryDomain?`.
- `HistoryPaginationDomain` — `total: Int`, `limit: Int`, `offset: Int`, `hasMore: Bool`.

All domain models are `Equatable` and `Sendable`.

## DTO → Domain Mapping

DTOs live in `HistoryDTOs.swift`; the two `data` DTOs conform to `ResponseProtocol`, the rest to
`Decodable, Sendable`. Snake_case wire keys are remapped via `CodingKeys`.

| DTO | Notable key mappings | `toModel()` target |
|---|---|---|
| `HistoryVehicleSummaryDTO` | — (all camelCase already) | `HistoryVehicleSummaryDomain` |
| `HistoryPartSummaryDTO` | `name_tr`, `name_sv`, `part_number`, `thumbnail_url`, `oem_number`, `cross_references`, `category_tecdoc`, `vehicle_compatible`, `image_url`, `confidence_score` | `HistoryPartSummaryDomain` |
| `ScanDetailItemDTO` | `input_type`, `input_text`, `ai_status`, `created_at`, `updated_at`, `vehicle_id` | `ScanDetailItemDomain` (maps `ai_status` via `ScanAiStatusDomain(rawValue:)`, unknown → `nil`) |
| `ScanArtifactDTO` | `artifact_type`, `ocr_raw_text`, `thumbnail_url` | `ScanArtifactDomain` (maps `artifact_type` via `ScanArtifactTypeDomain(rawValue:)`, unknown → `nil`) |
| `ScanDetailDataDTO` (`ResponseProtocol`) | `selected_part` | `ScanDetailDomain` |
| `HistoryScanItemDTO` | `created_at`, `selected_part` | `HistoryScanSummaryDomain` |
| `HistoryPaginationDTO` | `has_more` | `HistoryPaginationDomain` |
| `HistoryListDataDTO` (`ResponseProtocol`) | — | `HistoryPageDomain` |

Unknown `ai_status` / `artifact_type` strings decode to `nil` (via `flatMap` on the enum initializer)
rather than failing the whole response.

## History List Flow (`HistoryListViewModel`)

`@MainActor @Observable`. Observable state:
- `state: ViewState<[HistoryScanSummaryDomain]>` (`.idle` / `.loading` / `.loaded` / `.empty` / `.error`).
- `scans: [HistoryScanSummaryDomain]` — the in-memory accumulator the list renders from.
- `pagination: HistoryPaginationDomain?` — last page's pagination block; `hasMore` gates `loadMore()`.
- `isLoadingMore: Bool` — drives the bottom spinner row in the list.
- `transientError: String?` — one-shot message for failures that keep existing data on screen.

Private guards: `isRefreshing: Bool`, plus `vehicleId`, `historyRepository`, and `pageSize = 20`.

### Initial load — `loadInitial()`
- If `scans` is already non-empty it delegates to `refresh()` (the cached VM is being re-shown, so
  reload-in-place instead of flashing a spinner).
- Otherwise sets `state = .loading`, fetches `offset: 0`, then assigns `scans` / `pagination` and sets
  `state` to `.empty` (no scans) or `.loaded(page.scans)`.
- `CancellationError` while `.loading` resets `state` back to `.idle` so the cached VM's next `.task`
  reloads instead of spinning forever. `HistoryError` → `state = .error(error.localizedMessage)`;
  any other error → `state = .error(Localized.Error.unknown.localized)`.
- The view runs `loadInitial()` from `.task` only when `state == .idle`.

### Pull-to-refresh — `refresh()`
- Mutual-exclusion guard: returns early unless `!isRefreshing && !isLoadingMore`. This prevents a
  refresh from replacing `scans` while a stale-offset `loadMore()` page is being appended (which would
  duplicate `ForEach` IDs). Sets `isRefreshing = true` with a `defer` reset.
- Fetches `offset: 0`, replaces `scans` / `pagination`, recomputes `state` (`.empty` / `.loaded`).
- `CancellationError` is swallowed (existing data kept, no feedback). `HistoryError` and other errors
  set `transientError` instead of clobbering `state`, so the loaded list stays visible.
- Triggered by the view's `.refreshable`.

### Load-more (infinite scroll) — `loadMore()`
- Guard: returns unless `pagination?.hasMore == true && !isLoadingMore && !isRefreshing`.
- Sets `isLoadingMore = true` (with `defer` reset), fetches `offset: scans.count`, then
  `scans.append(contentsOf:)`, updates `pagination`, and sets `state = .loaded(scans)`.
- `CancellationError` swallowed; `HistoryError` / other errors → `transientError`.
- Triggered when the last row appears: the view's `.onAppear` on each row checks
  `scan.id == viewModel.scans.last?.id`. While appending, the list shows a trailing `ProgressView`
  row gated on `isLoadingMore`.

### Transient error UX
- `transientError` is rendered as a bottom banner overlay in `HistoryListView`. The banner auto-dismisses
  after a 3-second `Task.sleep` (calling `clearTransientError()`), and also dismisses on tap.
- `clearTransientError()` simply nils `transientError`.

### Race / duplicate guards (summary)
- `refresh()` and `loadMore()` are mutually exclusive via `isRefreshing` + `isLoadingMore`.
- `loadMore()` additionally requires `pagination.hasMore`, preventing over-fetch past the last page.
- `loadInitial()` short-circuits to `refresh()` when data already exists, avoiding a spinner flash and
  duplicate first-page loads.

## Scan Detail Flow (`ScanDetailViewModel`)

`@MainActor @Observable`. State: `state: ViewState<ScanDetailDomain>` plus private `scanId` and
`historyRepository`. `load()` sets `.loading`, calls `fetchScan(scanId:)`, then `.loaded(detail)`;
`HistoryError` → `.error(error.localizedMessage)`, other errors → `.error(Localized.Error.unknown.localized)`.
The view runs `load()` from `.task` only when `state == .idle`; the error state offers a retry that calls
`load()` again.

`ScanDetailView` renders, in order: an optional vehicle card (`"{year} {make} {model}"`); a scan-info
card (`state`, and `inputText` when non-empty); a photos grid built from artifacts filtered to
`.photo` / `.thumbnail` (3-column `LazyVGrid` of `AsyncImage` from `thumbnailUrl`); and an optional
selected-part card showing `part.name` + `part.partNumber`, with a "View Offers" button shown only when
`state == "OFFERS_READY"` (calls `onViewOffers(scanId)`). The `.empty` state renders `EmptyView()`.

## Row Rendering (`HistoryScanRowView`)

Each row is a plain `Button` containing a leading state badge, a title/subtitle stack, and a trailing
`chevron.right`. Styling: `Color.sbSurfaceSecondary` background, `.default` corner radius, `.soft` shadow.

- **Title**: `scan.selectedPart?.name` when present, otherwise `stateLabel`.
- **Subtitle**: `"{year} {make} {model}"` when `scan.vehicle != nil`, plus a right-aligned formatted date.
- **State badge** (`scan.state` switch):
  | State | Icon | Color |
  |---|---|---|
  | `OFFERS_READY` | `checkmark.seal.fill` | `sbStatusSuccess` |
  | `DISAMBIGUATION` | `questionmark.circle.fill` | `sbStatusWarning` |
  | `FAILED` | `exclamationmark.triangle.fill` | `sbStatusError` |
  | (default) | `clock.fill` | `sbTextTertiary` |
- **State label** (used as title fallback): `OFFERS_READY` → `Localized.Scan.resultTitle`;
  `DISAMBIGUATION` → `Localized.Scan.disambiguationTitle`; `FAILED` → `Localized.Scan.failedTitle`;
  `INPUT_COLLECTED` → `Localized.Scan.processing`; default → the raw `scan.state` string.
- **Date**: parses `createdAt` with two `ISO8601DateFormatter`s — `[.withInternetDateTime,
  .withFractionalSeconds]` first, then `[.withInternetDateTime]` (Supabase omits fractional seconds
  when they are exactly zero). On parse failure it falls back to the raw `createdAt` string; on success
  it renders via a `DateFormatter` with `.medium` date and `.short` time.

## Navigation & Wiring

History screens live in the **Scan tab's** `NavigationStack` (see `AppRouter.ScanRoute`):
- `.history` → `HistoryListView`. Tapping a row calls `onScanTap(scanId)` which appends
  `.scanDetail(scanId:)`.
- `.scanDetail(scanId:)` → `ScanDetailView`. "View Offers" appends `.offers(scanId:)`.

Entry points:
- Scan home → `onHistory` appends `.history` to `scanPath`.
- Garage → `VehicleDetailView` embeds a vehicle-filtered `historyListVM(env:vehicleId:)`; tapping a scan
  switches to the scan tab and sets `scanPath = [.scanDetail(scanId:)]`.

### ViewModel caching (`ViewModelCache`)
- `historyListVM(env:vehicleId:)` keys VMs by `vehicleId ?? "all"`, so the unfiltered list and each
  per-vehicle list are distinct cached instances.
- `scanDetailVM(env:scanId:)` keys VMs by `scanId`.
- The cache hands back the same VM instance until explicitly invalidated, preserving in-flight state
  across SwiftUI body re-evaluations.

### Cache invalidation and the Offer cache
History and Offers share invalidation because a scan's selected part (and therefore its offers and its
cached detail) can change after processing or disambiguation:
- `invalidateHistory()` — removes **all** history list VMs, **all** scan-detail VMs, **and all offers
  list VMs** (`historyListVMs`, `scanDetailVMs`, `offersListVMs` all `removeAll()`). Called from
  `MainTabView.handleProcessResult` right after a scan finishes processing, so the next time History,
  Scan Detail, or Offers is shown it refetches.
- `invalidateScanDetail(scanId:)` — removes just that scan's detail VM and that scan's offers VM
  (`scanDetailVMs` + `offersListVMs` `removeValue(forKey:)`). Called from the disambiguation completion
  handler, because selecting a part changes that scan's detail and offers.

## Error Handling

`HistoryError` (Equatable) maps `HTTPClientError` cases; `HTTPClientError` is never exposed beyond the
repository. Cases: `.invalidUUID`, `.scanNotFound`, `.invalidPagination`, `.tokenExpired`,
`.rateLimitExceeded`, `.network`, `.emptyResponse`, `.unknown`.

Both repository methods wrap their work in a `do/catch` that, in order:
1. Re-throws `CancellationError` and `URLError.cancelled` as `CancellationError` (so VMs can keep data).
2. Re-throws an already-typed `HistoryError` unchanged (covers the `.emptyResponse` guard below).
3. Maps `HTTPClientError` via `mapSingleError` (`fetchScan`) or `mapHistoryError` (`fetchHistory`).
4. Maps anything else to `.unknown`.

Before mapping, both methods validate the envelope with
`guard let envelope, envelope.success, envelope.data != nil else { throw .emptyResponse }`.

### Mapping table

| Case | `fetchScan` (`mapSingleError`) | `fetchHistory` (`mapHistoryError`) |
|---|---|---|
| `.scanNotFound` | `HTTPClientError.notFound` (404) | — (not produced) |
| `.rateLimitExceeded` | `clientError(statusCode: 429, _)` | `clientError(statusCode: 429, _)` |
| `.invalidUUID` | Any other `clientError` — **both** body-code branches (`INVALID_UUID` and default) return `.invalidUUID` | `clientError` whose body code parses to `INVALID_UUID` |
| `.invalidPagination` | — (not produced) | `clientError` whose body code is anything other than `INVALID_UUID` (including unparseable / `nil`) |
| `.tokenExpired` | `unauthorized` (401) | `unauthorized` (401) |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` | `.notConnectedToInternet` / `.networkConnectionLost` |
| `.emptyResponse` | Nil envelope, `success == false`, or `data == nil` | Nil envelope, `success == false`, or `data == nil` |
| `.unknown` | All other `HTTPClientError` cases + non-`HTTPClientError` throws | All other `HTTPClientError` cases + non-`HTTPClientError` throws |

Body codes are parsed by `APIErrorParser.code(from:)`, which decodes the `{ error: { code } }` 4xx body
into `APIErrorCode`; `INVALID_UUID` is the only code these maps branch on. Note that in `mapSingleError`
the non-404, non-429 `clientError` switch collapses both `APIErrorCode` branches to `.invalidUUID`, so a
single-scan client error never becomes `.invalidPagination`.

### Surfacing to the UI
ViewModels do **not** collapse failures to a single generic message. They call
`HistoryError.localizedMessage` (defined as an extension in `HistoryModule.swift`):

| `HistoryError` case | Localized message |
|---|---|
| `.scanNotFound` | `Localized.Error.scanNotFound` |
| `.tokenExpired` | `Localized.Error.tokenExpired` |
| `.rateLimitExceeded` | `Localized.Error.rateLimitExceeded` |
| `.network` | `Localized.Error.network` |
| default (`.invalidUUID`, `.invalidPagination`, `.emptyResponse`, `.unknown`) | `Localized.Error.unknown` |

`HistoryListViewModel` routes these to `state = .error(...)` on initial load and to `transientError`
on refresh/load-more; `ScanDetailViewModel` routes them to `state = .error(...)`. Errors that are not
`HistoryError` (should not occur after repository mapping) fall back to `Localized.Error.unknown`.

## Ownership / Cross-user behavior

- Single mode: cross-user scan access → 404 → `.scanNotFound`.
- History mode: cross-user `vehicle_id` → 200 with empty `scans` list (no data leak), rendered as the
  empty state.

## Model alignment with other modules

| Shape | Backend name | Defined in |
|---|---|---|
| `{ id, make, model, year }` | VehicleSummary | `HistoryVehicleSummaryDomain` (History) / `VehicleDomain` (Vehicle, richer) |
| Layer-1 part shape (`part_number`, `oem_number`, …) | SelectedPartSummary | `HistoryPartSummaryDomain` (History) / `ScanPartSummaryDomain` (Scan) / `OfferPartSummaryDomain` (Offer) |

Features define these shapes independently to preserve isolation; keep all three part summaries in sync
when Layer 1 evolves.

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; history is fetched from the backend on demand. `HistoryListViewModel` keeps the
  loaded page(s) in memory (`scans`) and appends on `loadMore()`. `refresh()` and `loadMore()` keep
  existing data on failure and surface a transient banner instead of clearing the list. ViewModel
  lifetime (and thus the in-memory page) is governed by `ViewModelCache` and its invalidation hooks.

## Open Questions / TODO

- Add local caching for offline history browsing.
