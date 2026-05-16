# History Module

## Responsibilities

- Fetch full details of a single scan via `scan-get?scanId={uuid}`.
- Fetch a paginated list of the user's scans via `scan-get?action=history`.

## Public Contracts

- Domain Interfaces:
  - `HistoryRepositoryProtocol`

## Data Dependencies

| Endpoint | Path | Method | Mode |
|---|---|---|---|
| `scan-get` (single) | `/functions/v1/scan-get?scanId={uuid}` | GET | Single scan |
| `scan-get` (history) | `/functions/v1/scan-get?action=history` | GET | Paginated list |

## Domain Models

### Shared sub-objects
- `HistoryVehicleSummaryDomain` — id, make, model, year (defined independently; History must not import Vehicle)
- `HistoryPartSummaryDomain` — id, name, partNumber, thumbnailUrl (defined independently; History must not import Scan or Offer)

### Single scan
- `ScanDetailDomain` — scan, vehicle?, artifacts, selectedPart?
- `ScanDetailItemDomain` — id, state, inputType, inputText, aiStatus, createdAt, updatedAt, vehicleId
- `ScanAiStatusDomain` — `.confident` | `.ambiguous` | `.needsInfo` | `.failed`
- `ScanArtifactDomain` — id, artifactType, ocrRawText, thumbnailUrl
- `ScanArtifactTypeDomain` — `.photo` | `.ocrResult` | `.thumbnail` | `.qa`

### History list
- `HistoryPageDomain` — scans, pagination
- `HistoryScanSummaryDomain` — id, state, createdAt, vehicle?, selectedPart?
- `HistoryPaginationDomain` — total, limit, offset, hasMore

## Repository Protocol

```swift
func fetchScan(scanId: String) async throws -> ScanDetailDomain
func fetchHistory(vehicleId: String?, limit: Int, offset: Int) async throws -> HistoryPageDomain
```

## Query Parameters

### Single mode
| Param | Required | Description |
|---|---|---|
| `scanId` | Yes | UUID of the scan |

### History mode
| Param | Required | Default | Description |
|---|---|---|---|
| `action` | Yes | — | Must be `"history"` |
| `vehicle_id` | No | nil | Filter by vehicle |
| `limit` | No | 20 | Page size (max 50) |
| `offset` | No | 0 | Pagination offset |

## Error Handling

`HistoryError` maps `HTTPClientError` by status code:

| Case | Trigger |
|---|---|
| `.invalidUUID` | 400 — invalid scanId or vehicle_id |
| `.scanNotFound` | 404 — scan not found or not owned (single mode) |
| `.invalidPagination` | 400 — negative or non-integer limit/offset (history mode) |
| `.rateLimitExceeded` | 429 |
| `.network` | No connectivity |
| `.emptyResponse` | Nil envelope |
| `.unknown` | All other errors |

## Ownership / Cross-user behavior

- Single mode: cross-user scan access → 404 SCAN_NOT_FOUND
- History mode: cross-user `vehicle_id` → 200 with empty `scans` list (no data leak)

## Model alignment with other modules

| Shape | Backend name | Defined in |
|---|---|---|
| `{ id, make, model, year }` | VehicleSummary | `HistoryVehicleSummaryDomain` (History) / `VehicleDomain` (Vehicle, richer) |
| `{ id, name, part_number, thumbnail_url }` | SelectedPartSummary | `HistoryPartSummaryDomain` (History) / `OfferPartSummaryDomain` (Offer) |

Features define these shapes independently to preserve isolation.

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; history is fetched from backend on demand.

## Open Questions / TODO

- Add local caching for offline history browsing.
- Consider exposing a `fetchHistory(vehicleId:limit:offset:)` convenience overload with default values.
