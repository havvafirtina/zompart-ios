# History Module

## Responsibilities

- Fetch full details of a single scan via `scan-get?scanId={uuid}`.
- Fetch a paginated list of the user's scans via `scan-get?action=history`.

## Public Contracts

- Domain Interfaces:
  - `HistoryRepositoryProtocol`

## Data Dependencies

| Endpoint | Path | Method | Response | Mode |
|---|---|---|---|---|
| `ScanGetSingleEndpoint` | `/functions/v1/scan-get?scanId={uuid}` | GET | `APIEnvelope<ScanDetailDataDTO>` | Single scan |
| `ScanGetHistoryEndpoint` | `/functions/v1/scan-get?action=history` | GET | `APIEnvelope<HistoryListDataDTO>` | Paginated list |

Both endpoints share the path `/functions/v1/scan-get` and differ only by query parameters.

## Domain Models

### Shared sub-objects
- `HistoryVehicleSummaryDomain` — id, make, model, year (defined independently; History must not import Vehicle)
- `HistoryPartSummaryDomain` — id, name, nameTr?, nameSv?, partNumber, thumbnailUrl?, plus Layer-1 canonical enrichment: oemNumber?, mpn?, ean?, brand?, manufacturer?, crossReferences?, categoryTecdoc?, vehicleCompatible?, imageUrl?, confidenceScore?. Computed: `localizedName` (locale-aware), `displayImageUrl` (imageUrl ?? thumbnailUrl). Defined independently; History must not import Scan or Offer. Mirrors `ScanPartSummaryDomain` and `OfferPartSummaryDomain`.

### Single scan
- `ScanDetailDomain` — scan, vehicle?, artifacts, selectedPart?
- `ScanDetailItemDomain` — id, state, inputType?, inputText?, aiStatus?, createdAt, updatedAt, vehicleId?
- `ScanAiStatusDomain` — `.confident` (`CONFIDENT`) | `.ambiguous` (`AMBIGUOUS`) | `.needsInfo` (`NEEDS_INFO`) | `.failed` (`FAILED`)
- `ScanArtifactDomain` — id, artifactType?, ocrRawText?, thumbnailUrl?
- `ScanArtifactTypeDomain` — `.photo` (`PHOTO`) | `.ocrResult` (`OCR_RESULT`) | `.thumbnail` (`THUMBNAIL`) | `.qa` (`QA`)

### History list
- `HistoryPageDomain` — scans, pagination
- `HistoryScanSummaryDomain` — id, state, createdAt, vehicle?, selectedPart?
- `HistoryPaginationDomain` — total, limit, offset, hasMore

## Repository Protocol

```swift
func fetchScan(scanId: String) async throws -> ScanDetailDomain
func fetchHistory(vehicleId: String?, limit: Int, offset: Int) async throws -> HistoryPageDomain
```

No default-argument overloads; `vehicleId`, `limit`, and `offset` are always passed explicitly by the caller (`HistoryListViewModel` uses `pageSize = 20`).

## Query Parameters

### Single mode (`ScanGetSingleEndpoint`)
| Param | Required | Description |
|---|---|---|
| `scanId` | Yes | UUID of the scan |

### History mode (`ScanGetHistoryEndpoint`)
| Param | Required | Default | Description |
|---|---|---|---|
| `action` | Yes | — | Always sent as `"history"` |
| `limit` | Yes | — | Page size, always sent (backend defaults to 20, max 50) |
| `offset` | Yes | — | Pagination offset, always sent |
| `vehicle_id` | No | omitted | Filter by vehicle; only added when `vehicleId != nil` |

## Error Handling

`HistoryError` maps `HTTPClientError` cases; `HTTPClientError` is never exposed beyond the repository.
`fetchScan` uses `mapSingleError`, `fetchHistory` uses `mapHistoryError`. Repositories also validate
`envelope != nil`, `envelope.success`, and `envelope.data != nil` before calling `toModel()`.

| Case | Trigger |
|---|---|
| `.invalidUUID` | Single: any non-404 `clientError` (default). History: `clientError` whose body code is `INVALID_UUID` |
| `.scanNotFound` | Single only — `HTTPClientError.notFound` (404), scan missing or not owned |
| `.invalidPagination` | History only — `clientError` whose body code is not `INVALID_UUID` |
| `.tokenExpired` | `HTTPClientError.unauthorized` (401) |
| `.rateLimitExceeded` | `clientError` with status 429 |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` |
| `.emptyResponse` | Nil envelope, `success: false`, or `data == nil` |
| `.unknown` | All other errors (and non-`HTTPClientError` throws) |

Both ViewModels surface failures generically as `Localized.Error.network`; the granular cases above are
available to the repository layer but not yet differentiated in the UI.

## Ownership / Cross-user behavior

- Single mode: cross-user scan access → 404 → `.scanNotFound`.
- History mode: cross-user `vehicle_id` → 200 with empty `scans` list (no data leak).

## Model alignment with other modules

| Shape | Backend name | Defined in |
|---|---|---|
| `{ id, make, model, year }` | VehicleSummary | `HistoryVehicleSummaryDomain` (History) / `VehicleDomain` (Vehicle, richer) |
| Layer-1 part shape (`part_number`, `oem_number`, …) | SelectedPartSummary | `HistoryPartSummaryDomain` (History) / `ScanPartSummaryDomain` (Scan) / `OfferPartSummaryDomain` (Offer) |

Features define these shapes independently to preserve isolation; keep all three part summaries in sync when Layer 1 evolves.

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; history is fetched from backend on demand. `HistoryListViewModel` keeps the
  loaded page in memory and appends on `loadMore()`; `refresh()` and `loadMore()` fail silently to
  preserve existing data.

## Open Questions / TODO

- Add local caching for offline history browsing.
- Differentiate `HistoryError` cases in the UI instead of collapsing all failures to a generic network message.
- Consider a `fetchHistory(vehicleId:limit:offset:)` convenience overload with default values.
