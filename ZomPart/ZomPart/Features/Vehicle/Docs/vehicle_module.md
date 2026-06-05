# Vehicle Module

## Responsibilities

- List vehicles in the user's garage via `GET vehicle-resolve`.
- Resolve vehicle identity by VIN, PLATE, PERSON number, or COMPANY number via `POST vehicle-resolve`.
- Drive a multi-step MANUAL vehicle entry flow (YEAR → MAKE → MODEL → TRIM → ENGINE).

> **iOS UI scope:** the current `AddVehicleSheetView` only exposes **VIN** and **Plate**
> scanner buttons. The MANUAL wizard (`ManualWizardCoordinatorView`) and PERSON / COMPANY
> resolution are fully implemented in the repository, domain, and module factory, but no
> button surfaces them yet. The garage list (`GarageListView`) is wired in `MainTabView`.

## Public Contracts

- Domain Interfaces:
  - `VehicleRepositoryProtocol` — `listVehicles()`, `resolveByVIN(_:countryCode:)`,
    `resolveByPlate(_:countryCode:)`, `resolveByPersonNumber(_:countryCode:)`,
    `resolveByOrganizationNumber(_:countryCode:)`, `fetchManualSession()`,
    `submitManualStep(_:sessionId:countryCode:)`.
- Factory: `VehicleModule` (enum) wires repository → `GarageListViewModel`,
  `VINScannerViewModel`, `PlateScannerViewModel`, `ManualWizardViewModel`.

## Data Dependencies

- Endpoint: `vehicle-resolve` (single path, GET + POST)
  - `GET /functions/v1/vehicle-resolve` — list garage (`VehicleListEndpoint`)
  - `POST /functions/v1/vehicle-resolve` — resolve by type (`resolve_type` in body)
    - VIN: `{ resolve_type: "VIN", vin, country_code }`
    - PLATE: `{ resolve_type: "PLATE", plate, country_code }`
    - PERSON: `{ resolve_type: "PERSON", person_number, country_code }`
    - COMPANY: `{ resolve_type: "COMPANY", organization_number, country_code }`
    - MANUAL lookup: `{ resolve_type: "MANUAL" }`
    - MANUAL step: `{ resolve_type: "MANUAL", session_id?, current_step, country_code, year?, make?, model?, trim?, engine_code? }`
- All responses decode as `APIEnvelope<VehicleResolveDataDTO>`, where the `data` payload is
  `{ "vehicles": [VehicleDTO], "resolution": VehicleResolutionDTO | null }`.

## Domain Models

- `VehicleDomain` — id, make, model, year (Int?), engineCode (String?), trim (String?),
  resolveMethod, countryCode, vin (String?), plate (String?)
- `VehicleResolveMethodDomain` — `.vin` | `.plate` | `.person` | `.company` | `.manual`
  (raw values `VIN` / `PLATE` / `PERSON` / `COMPANY` / `MANUAL`)
- `VehicleResolveResultDomain` — vehicle + `isNew` flag
- `VehicleManualStepDomain` — `.year` | `.make` | `.model` | `.trim` | `.engine`
  (raw values `YEAR` … `ENGINE`); `isOptional` true for `.trim` / `.engine`
- `VehicleManualStepValueDomain` — typed step value (year: Int, make/model: String, trim/engine: String?)
- `VehicleManualCompletedStepDomain` — step, value (String), isOptional
- `VehicleManualSessionDomain` — sessionId, nextStep, nextStepIsOptional, options, completedSteps
- `VehicleManualResultDomain` — `.resolved(VehicleResolveResultDomain)` | `.inProgress(VehicleManualSessionDomain)`

## MANUAL Flow

```
fetchManualSession()          → VehicleManualSessionDomain? (resume pending session, or nil)

submitManualStep(.year(2022), sessionId: nil, countryCode: "SE")
  → .inProgress(session) — nextStep: .make, options: [...]

submitManualStep(.make("Volvo"), sessionId: "...", countryCode: "SE")
  → .inProgress(session) — nextStep: .model, options: [...]

submitManualStep(.model("XC60"), sessionId: "...", countryCode: "SE")
  → .inProgress(session) — nextStep: .trim (optional), options: [...]

submitManualStep(.trim(nil), sessionId: "...", countryCode: "SE")   // skip TRIM
  → .inProgress(session) — nextStep: .engine (optional)

submitManualStep(.engine("B5"), sessionId: "...", countryCode: "SE")
  → .resolved(VehicleResolveResultDomain) — vehicle created
```

`.trim` and `.engine` are optional; passing `nil` skips them (encoded as null in the body).
The repository returns `.resolved` only when `resolution.isResolved == true` and a vehicle is
present; otherwise it extracts the next session and returns `.inProgress`.

## Deduplication

| Type | Behavior |
|---|---|
| VIN | Same user + VIN → same vehicle; `isNew: false`; existing `country_code` preserved |
| PLATE | Same user + plate + country → same vehicle; different country → new vehicle |
| PERSON / COMPANY | Currently creates separate vehicles (policy TBD) |
| MANUAL | Always creates a new vehicle |

> Dedup logic lives on the backend; iOS only reads the `is_new` flag returned in `resolution`.

## Error Handling

`VehicleError` maps `HTTPClientError`. `HTTPClient` exposes a dedicated `.notFound` case for 404.
Repositories validate `envelope.success` and `envelope.data != nil` before calling `toModel()`.
The body's error `code` is read by `APIErrorParser.code(from:)` on `clientError` responses.

| Case | Trigger |
|---|---|
| `.invalidVIN` | 400 — `INVALID_VIN` |
| `.invalidPlate` | 400 — `INVALID_PLATE` |
| `.invalidPersonNumber` | 400 — `INVALID_PERSON_NUMBER` |
| `.invalidOrganizationNumber` | 400 — `INVALID_ORGANIZATION_NUMBER` |
| `.invalidCountryCode` | 400 — `INVALID_COUNTRY_CODE`; also PERSON/COMPANY 400 fallback |
| `.invalidStep` | 400 — `INVALID_STEP` on MANUAL step (also the default for unmatched MANUAL 4xx) |
| `.invalidSession` | 400 — `INVALID_SESSION` on MANUAL session_id mismatch |
| `.vehicleNotFound` | 404 (`.notFound`) on resolve, list, and MANUAL; or empty `vehicles` on resolve |
| `.tokenExpired` | 401 (`.unauthorized`) — Bearer token expired |
| `.rateLimitExceeded` | 429 |
| `.providerUnavailable` | 5xx (`.serverError`) |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` |
| `.emptyResponse` | Nil envelope, `success: false`, or nil `data` |
| `.unknown` | All other errors |

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; vehicles fetched from backend on demand.

## Domain Models (Architecture Note)

`VehicleResolutionDomain` is the domain-layer representation of resolution metadata. It replaced
the direct usage of `VehicleResolutionDTO` inside `VehicleResponseDomain`, ensuring the Data layer
never leaks DTO types into domain code. `VehicleResponseDomain` itself is a Data-layer-internal
type used only by the repository to extract the specific return value before crossing into domain.

## Open Questions / TODO

- Define and apply a PERSON/COMPANY dedup policy when clarified.
- Integrate real Biluppgifter provider via `VEHICLE_PROVIDER` env var (backend).
- Surface the MANUAL wizard and PERSON/COMPANY resolution in `AddVehicleSheetView`
  (today only VIN + Plate buttons are exposed).
