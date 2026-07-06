# Vehicle Module

## Responsibilities

- List the vehicles in the user's garage via `GET vehicle-resolve` (`GarageListView`).
- Resolve a vehicle by **VIN** or **PLATE** via `POST vehicle-resolve`, adding it to the
  garage (`VINScannerView`, `PlateScannerView`).
- Capture VIN / plate text either from the live camera (on-device VisionKit `DataScanner`)
  or from a still photo (Vision OCR), with manual text entry as a fallback.
- Show a single vehicle's details plus its scan history (`VehicleDetailView`).

> **Scope note:** the app only supports **VIN** and **PLATE** resolution. The backend
> contract still defines PERSON, COMPANY and MANUAL resolve types, but they have no
> endpoints, repository methods, domain flow, or UI in this app — the manual-entry wizard
> and the PERSON/COMPANY paths were removed. Do not document them as available features.
>
> **VIN is hidden from the UI:** plate is the primary path, so `AddVehicleSheetView`
> exposes only the Plate scanner button. The VIN flow (`VINScannerView`, its ViewModel,
> and the `.vinScanner` route) stays implemented but dormant — re-adding the method
> button is enough to re-enable it.

## Public Contracts

- Domain Interface: `VehicleRepositoryProtocol` (`Sendable`)
    - `func listVehicles() async throws -> [VehicleDomain]`
    - `func resolveByVIN(_ vin: String, countryCode: String) async throws -> VehicleResolveResultDomain`
    - `func resolveByPlate(_ plate: String, countryCode: String) async throws -> VehicleResolveResultDomain`
- Factory: `VehicleModule` (enum) — composition root for the feature.
    - `makeVehicleRepository(httpClient:) -> VehicleRepositoryProtocol`
    - `makeGarageListViewModel(env:) -> GarageListViewModel`
    - `makeVINScannerViewModel(env:onVehicleAdded:) -> VINScannerViewModel`
    - `makePlateScannerViewModel(env:onVehicleAdded:) -> PlateScannerViewModel`
    - `onVehicleAdded` is an `@escaping (VehicleDomain) -> Void` callback receiving the
      resolved vehicle, so list screens can insert it optimistically without re-fetching.
    - The factory also defines `VehicleError.localizedMessage`, which maps each error case to a
      `Localized.*` string (used by the scanner view models for on-screen messages).

## Data Dependencies

- Single edge function path: `/functions/v1/vehicle-resolve` (shared by GET and POST).
- **List garage** — `VehicleListEndpoint` (via `VehicleListRequest`)
    - `GET /functions/v1/vehicle-resolve`, no payload, Bearer token required.
- **Resolve by VIN** — `VehicleResolveVINEndpoint` (via `VehicleResolveVINRequest`)
    - `POST /functions/v1/vehicle-resolve`
    - Body keys: `{ "resolve_type": "VIN", "vin": <string>, "country_code": <string> }`
- **Resolve by PLATE** — `VehicleResolvePlateEndpoint` (via `VehicleResolvePlateRequest`)
    - `POST /functions/v1/vehicle-resolve`
    - Body keys: `{ "resolve_type": "PLATE", "plate": <string>, "country_code": <string> }`
- All three endpoints declare `ResponseType = APIEnvelope<VehicleResolveDataDTO>`.
- Plate resolve sends the user-selected `PlateCountry` (SE/NO/DK/FI picker in
  `PlateScannerView`; last choice persisted under the `plate_country` UserDefaults key,
  default SE). FI is licensed but currently rejected at the TecAlliance account level —
  the backend answers `503 PROVIDER_UNAVAILABLE` and the VM shows the dedicated
  `garage.error.finlandComingSoon` message (self-heals when the vendor ticket closes).
  VIN resolve still hard-codes `"SE"` (the VIN flow is dormant/hidden).

### Response shape

Every response decodes as `APIEnvelope<VehicleResolveDataDTO>`:

```
{ "success": Bool, "data": { ... } | null, "meta": APIMeta | null }
```

The `data` payload (`VehicleResolveDataDTO`) is:

```
{ "vehicles": [VehicleDTO], "resolution": VehicleResolutionDTO | null }
```

`APIEnvelope.toModel()` precondition-fails on nil `data`, so every repository call site
guards `envelope != nil && envelope.success && envelope.data != nil` before mapping.

## DTOs → Domain Mappings

- `VehicleDTO → VehicleDomain` (`toModel()`):
    - JSON keys `engine_code`, `resolve_method`, `country_code` map to
      `engineCode`, `resolveMethod`, `countryCode`; `id`, `make`, `model`, `year`,
      `trim`, `vin`, `plate` map by name.
    - `resolveMethod` is parsed into `VehicleResolveMethodDomain(rawValue:)`, falling back
      to `.manual` when the raw value is unrecognized.
    - `year`, `engineCode`, `trim`, `vin`, `plate` are optional; `make`, `model`,
      `countryCode`, `id`, `resolveMethod` are required.
- `VehicleResolutionDTO → VehicleResolutionDomain` (`toModel()`):
    - Keys `is_resolved`, `is_new`, `resolve_type` map to `isResolved` (Bool),
      `isNew` (Bool?), `resolveType` (String). `isNew` is optional.
- `VehicleResolveDataDTO → VehicleResponseDomain` (`toModel()`):
    - Maps each `VehicleDTO` and the optional `VehicleResolutionDTO`.
    - `VehicleResponseDomain` is a Data-layer-internal carrier; the repository reads it to
      extract the specific return value before returning a domain type.

## Domain Models

- `VehicleDomain` (`Equatable, Sendable`) — `id`, `make`, `model`, `year (Int?)`,
  `engineCode (String?)`, `trim (String?)`, `resolveMethod`, `countryCode`, `vin (String?)`,
  `plate (String?)`.
- `VehicleResolveMethodDomain` (`String`-backed enum):
  `.vin` (`VIN`), `.plate` (`PLATE`), `.person` (`PERSON`), `.company` (`COMPANY`),
  `.manual` (`MANUAL`). PERSON/COMPANY/MANUAL still exist as raw values because backend
  records can carry them, but the app never initiates those resolutions.
- `VehicleResolveResultDomain` (`Equatable, Sendable`) — `vehicle: VehicleDomain` plus an
  `isNew: Bool` flag (true when newly added; false when a duplicate was returned).
- `VehicleResolutionDomain` (`Equatable, Sendable`) — `resolveType (String)`,
  `isResolved (Bool)`, `isNew (Bool?)`. The wire object also carries multi-step session
  fields (session_id, next_step, completed_steps) for resolve types this app does not
  initiate; those fields are intentionally not decoded.

## Repository Flow

`VehicleRepository` is an `actor` holding an `HTTPClient`.

- `listVehicles()` submits `VehicleListRequest`, validates the envelope, and returns
  `envelope.toModel().vehicles`.
- `resolveByVIN` / `resolveByPlate` both delegate to a private generic
  `resolveAndExtract(request:on400:)` helper:
    - Validates the envelope, takes `response.vehicles.first` (throws `.vehicleNotFound`
      when empty), and reads `response.resolution?.isNew ?? true` for the `isNew` flag.
    - The `on400` argument supplies the fallback error for an unmatched 400
      (`.invalidVIN` for VIN, `.invalidPlate` for PLATE).
- Both paths translate cancellation explicitly: `CancellationError` and
  `URLError.cancelled` are re-thrown as `CancellationError` (never mapped to a domain error).

## Presentation

### Garage list (`GarageListView` + `GarageListViewModel`)

- State is `ViewState<[VehicleDomain]>` (`idle / loading / loaded / empty / error`).
- `loadVehicles()` — on first load fetches and filters; if vehicles already exist it
  delegates to `refresh()`. Cancellation mid-load resets a `loading` state back to `idle`.
- `refresh()` — re-fetches; on error it preserves existing vehicles instead of showing an
  error (falls back to `.empty` or `.loaded`). Bound to `.refreshable`.
- `onVehicleAdded(vehicle:)` — optimistically inserts the resolved vehicle at the top of
  the list (state goes straight to `.loaded`, never back to a spinner), then reconciles
  via `refresh()`; a failed reconcile keeps the optimistic data on screen. If the id was
  previously deleted, it is removed from the deleted-id set first so the vehicle reappears.
- **Local soft-delete:** swipe-to-delete calls `deleteVehicle(id:)`, which adds the id to a
  `Set<String>` persisted in `UserDefaults` under key `deleted_vehicle_ids`. `loadVehicles()`
  and `refresh()` filter the server response against this set, so deletes are client-side
  only (the backend list is not mutated).
- UI: empty state with an "Add vehicle" CTA, a `List` of `VehicleCardView` rows with
  trailing destructive swipe action, an error state with a Retry button, and a toolbar
  `+` button. `+` and the empty-state CTA both call `onAddVehicle`.

### Add vehicle (`AddVehicleSheetView`)

- Presented as a sheet from `MainTabView` (triggered from both the Garage and Scan tabs).
- Hosts its own `NavigationStack` with a local `Route` enum: `.vinScanner`, `.plateScanner`.
- Shows a single method button (Plate scanner) and a Cancel toolbar item; the VIN entry
  point is intentionally hidden (see scope note above).
- On `onVehicleAdded(vehicle)` it forwards the resolved `VehicleDomain` and dismisses
  the sheet; `MainTabView` fans the vehicle out to `GarageListViewModel` and
  `ScanHomeViewModel`, which insert it optimistically.

### VIN scanner (`VINScannerView` + `VINScannerViewModel`)

- State is `ViewState<VehicleResolveResultDomain>`; `manualVIN` is a bindable text field.
- "Open camera" calls `requestCameraAccess()` (`CameraPermissionManager`) and only presents
  the scanner when access is granted.
- Camera capture path (full-screen cover):
    - If `LiveTextScannerView.isDeviceSupported` (VisionKit `DataScannerViewController`
      supported), live text is recognized; the tapped transcript is stripped of spaces,
      uppercased, and written to `manualVIN`, then the cover dismisses.
    - Otherwise it falls back to `CameraPickerView` (`UIImagePickerController`). That picker
      defends against simulators / camera-less hardware by using `.photoLibrary` when
      `.camera` is unavailable. The captured image is passed to `processImage(_:)`.
- `processImage(_:)` runs `VisionOCRService.recognizeText` and tries `extractVIN`. OCR
  failures are swallowed (the user can still type). It resets `state` to `.idle`.
- VIN validation: `extractVIN` and `resolveEnteredVIN` use the regex `[A-HJ-NPR-Z0-9]{17}`
  (17 chars, ISO 3779 — I/O/Q excluded). Input is trimmed and uppercased. The Resolve
  button is disabled unless `manualVIN.count == 17`; on tap, a non-matching VIN sets
  `state = .error(errorInvalidVIN)`.
- On success: `state = .loaded(result)`, then a ~1.5s delay, then `onVehicleAdded(vehicle.id)`.

### Plate scanner (`PlateScannerView` + `PlateScannerViewModel`)

- Mirrors the VIN scanner structure (same live-text / photo-fallback / manual-entry layout).
- Plate validation is looser: `resolveEnteredPlate()` only trims, uppercases, and requires a
  non-empty value; the Resolve button is disabled while `manualPlate.isEmpty`.
- `extractPlate` uses the regex `[A-Z]{3}\s?\d{2}[A-Z0-9]` (Swedish-style plate) against
  OCR output, stripping any space from the match.
- On success: `state = .loaded(result)`, ~1.5s delay, then `onVehicleAdded(vehicle.id)`.

### Vehicle detail (`VehicleDetailView`)

- Reached via `AppRouter.GarageRoute.vehicleDetail(vehicleId:)` from `MainTabView`.
- Receives a resolved `VehicleDomain` plus a `HistoryListViewModel` scoped to that vehicle.
- Shows an info card (year/make/model, optional trim, VIN, plate, engine code) and a scan
  history section that loads on first appearance via `historyViewModel.loadInitial()`.
- Toolbar `viewfinder` button calls `onStartScan` (switches to the Scan tab). Tapping a
  history row calls `onScanTap(scanId)`.

### Shared components

- `VehicleCardView` — tappable card (title = year/make/model joined; subtitle = plate, else
  VIN, else `resolveMethod.rawValue`).
- `LiveTextScannerView` — `UIViewControllerRepresentable` wrapping VisionKit
  `DataScannerViewController` (text data type, `.accurate`, multi-item, draws custom yellow
  highlight overlays). Exposes static `isDeviceSupported` and `onTextRecognized` / `onDismiss`.
- `CameraPickerView` (defined in `VINScannerView.swift`) — `UIImagePickerController` wrapper
  used as the still-photo fallback by both scanners.

## Navigation Wiring

- `AppRouter.Tab.garage` is the Garage tab; `AppRouter.GarageRoute` has one case:
  `.vehicleDetail(vehicleId: String)`.
- `MainTabView` wires the Garage tab to `GarageListView`; tapping a card pushes
  `.vehicleDetail`. The detail destination resolves the vehicle from the cached
  `GarageListViewModel` (loading it first if empty) and renders loading / error /
  not-found fallbacks when the id is absent.
- `AddVehicleSheetView` is presented from `MainTabView` as a sheet (`showAddVehicle`),
  shared by the Garage `+`/empty-CTA and the Scan home "add vehicle" action. On success it
  refreshes both the garage list and the scan-home vehicle list via the view-model cache.

## Deduplication

| Type | Behavior |
|---|---|
| VIN | Same user + VIN → same vehicle; `is_new: false`; existing `country_code` preserved |
| PLATE | Same user + plate + country → same vehicle; different country → new vehicle |

> Dedup logic lives on the backend; iOS only reads the `is_new` flag from `resolution`
> (`response.resolution?.isNew ?? true`) to populate `VehicleResolveResultDomain.isNew`.
> Note this is independent of the **local** soft-delete in `GarageListViewModel`, which
> hides ids client-side via `UserDefaults`.

## Error Handling

`VehicleError` is the feature error type; `HTTPClientError` never leaks past the repository.
`HTTPClient` exposes a dedicated `.notFound` case for 404. On `.clientError`, the body's
error `code` is read by `APIErrorParser.code(from:)` and matched against `APIErrorCode`
(e.g. `INVALID_VIN`, `INVALID_PLATE`, `INVALID_COUNTRY_CODE`). Unmatched codes fall through
to the `default:` branch.

`VehicleError` cases (the only cases that exist):
`invalidVIN`, `invalidPlate`, `invalidCountryCode`, `vehicleNotFound`, `tokenExpired`,
`rateLimitExceeded`, `providerUnavailable`, `network`, `emptyResponse`, `unknown`.

Two mapping functions exist. `mapResolveError(_:on400:)` is used by VIN/PLATE resolve;
`mapCommonError(_:)` is used by `listVehicles()`. They differ only in the 400 fallback:

| `VehicleError` | Resolve (`mapResolveError`) | List (`mapCommonError`) |
|---|---|---|
| `.vehicleNotFound` | `.notFound` (404) | `.notFound` (404) |
| `.providerUnavailable` | `.serverError` (5xx) | `.serverError` (5xx) |
| `.rateLimitExceeded` | `clientError(429, _)` | `clientError(429, _)` |
| `.invalidVIN` | 4xx body code `INVALID_VIN` | 4xx body code `INVALID_VIN` |
| `.invalidPlate` | 4xx body code `INVALID_PLATE` | 4xx body code `INVALID_PLATE` |
| `.invalidCountryCode` | 4xx body code `INVALID_COUNTRY_CODE` | 4xx body code `INVALID_COUNTRY_CODE` |
| `.tokenExpired` | `.unauthorized` (401) | `.unauthorized` (401) |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` | same |
| `on400` fallback | unmatched 4xx → `on400` (`.invalidVIN` or `.invalidPlate`) | unmatched 4xx → `.unknown` |
| `.unknown` | any other `HTTPClientError` | any other `HTTPClientError` |

Additional non-`HTTPClientError` sources:

| `VehicleError` | Trigger |
|---|---|
| `.emptyResponse` | nil envelope, `success: false`, or nil `data` |
| `.vehicleNotFound` | empty `vehicles` array on a successful resolve |
| `.unknown` | any other thrown error |

`CancellationError` / `URLError.cancelled` are never mapped to a `VehicleError`; they are
re-thrown as `CancellationError` so callers can ignore cancellation.

View models surface errors via `VehicleError.localizedMessage` (defined in
`VehicleModule.swift`), which maps each case to a `Localized.*` string. Note that
`.emptyResponse` and `.unknown` fall into the `default:` branch and both render
`Localized.Error.unknown`.

## Analytics

- No analytics events defined for this scope. (No `Analytics` / `SBAnalytics` / `track`
  references exist anywhere under `Features/Vehicle`.)

## Persistence

- Vehicles are fetched from the backend on demand — there is no local cache of vehicle data.
- The only local persistence is the soft-delete set: `GarageListViewModel` stores hidden
  vehicle ids in `UserDefaults` under `deleted_vehicle_ids`.

## Architecture Notes

- `VehicleResolutionDomain` is the domain-layer representation of resolution metadata,
  keeping `VehicleResolutionDTO` out of domain code.
- `VehicleResponseDomain` is a Data-layer-internal carrier used only by the repository to
  extract the specific return value before crossing into the domain.
- Repositories are `actor` types (implicit `Sendable`); view models are
  `@MainActor @Observable`. The domain layer imports only `Foundation`.

## Open Questions / TODO

- The plate OCR hint regex is Swedish-specific; NO/DK/FI plates rely on manual entry
  (generalize the pattern per country if OCR matters there).
- Vehicle detail links into the Catalog feature ("Browse parts catalog" → `CatalogBrowseView`
  sheet); make/model rendering uses `String.displayCased` (prod TecDoc data arrives shouty).
- Soft-delete is local only; reconcile with a backend delete endpoint if/when one exists.
