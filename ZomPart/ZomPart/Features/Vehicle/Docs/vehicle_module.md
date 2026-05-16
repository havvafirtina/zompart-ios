# Vehicle Module

## Responsibilities

- List vehicles in the user's garage via `GET vehicle-resolve`.
- Resolve vehicle identity by VIN, PLATE, PERSON number, or COMPANY number via `POST vehicle-resolve`.
- Drive a multi-step MANUAL vehicle entry flow (YEAR → MAKE → MODEL → TRIM → ENGINE).

## Public Contracts

- Domain Interfaces:
  - `VehicleRepositoryProtocol`

## Data Dependencies

- Endpoint: `vehicle-resolve` (single path, GET + POST)
  - `GET /functions/v1/vehicle-resolve` — list garage
  - `POST /functions/v1/vehicle-resolve` — resolve by type

## Domain Models

- `VehicleDomain` — id, make, model, year, engineCode, trim, resolveMethod, countryCode, vin, plate
- `VehicleResolveMethodDomain` — `.vin` | `.plate` | `.person` | `.company` | `.manual`
- `VehicleResolveResultDomain` — vehicle + isNew flag
- `VehicleManualStepDomain` — `.year` | `.make` | `.model` | `.trim` | `.engine`
- `VehicleManualStepValueDomain` — typed step value (year: Int, make/model: String, trim/engine: String?)
- `VehicleManualSessionDomain` — sessionId, nextStep, nextStepIsOptional, options, completedSteps
- `VehicleManualResultDomain` — `.resolved(VehicleResolveResultDomain)` | `.inProgress(VehicleManualSessionDomain)`

## MANUAL Flow

```
fetchManualSession()          → VehicleManualSessionDomain? (resume or start fresh)

submitManualStep(.year(2022), sessionId: nil, countryCode: "SE")
  → .inProgress(session) — next_step: MAKE, options: [...]

submitManualStep(.make("Volvo"), sessionId: "...", countryCode: "SE")
  → .inProgress(session) — next_step: MODEL, options: [...]

submitManualStep(.model("XC60"), sessionId: "...", countryCode: "SE")
  → .inProgress(session) — next_step: TRIM (optional), options: [...]

submitManualStep(.trim(nil), sessionId: "...", countryCode: "SE")   // skip TRIM
  → .inProgress(session) — next_step: ENGINE (optional)

submitManualStep(.engine("B5"), sessionId: "...", countryCode: "SE")
  → .resolved(VehicleResolveResultDomain) — vehicle created
```

TRIM and ENGINE are optional; passing `nil` skips them (stored as null).

## Deduplication

| Type | Behavior |
|---|---|
| VIN | Same user + VIN → same vehicle; `isNew: false`; existing `country_code` preserved |
| PLATE | Same user + plate + country → same vehicle; different country → new vehicle |
| PERSON / COMPANY | Currently creates separate vehicles (policy TBD) |
| MANUAL | Always creates a new vehicle |

## Error Handling

`VehicleError` maps `HTTPClientError` cases. `HTTPClient` uses a dedicated `.notFound` case for 404.
Repositories also validate `envelope.success` and `envelope.data != nil` before calling `toModel()`.

| Case | Trigger |
|---|---|
| `.invalidVIN` | 400 on VIN resolve |
| `.invalidPlate` | 400 on PLATE resolve |
| `.invalidCountryCode` | 400 country_code validation |
| `.invalidStep` | 400 on MANUAL step |
| `.invalidSession` | 400 on MANUAL session_id mismatch (enum-only; not yet produced by mappers) |
| `.vehicleNotFound` | 404 (`.notFound`) on resolve, list, and MANUAL |
| `.rateLimitExceeded` | 429 |
| `.providerUnavailable` | 503 |
| `.network` | No connectivity |
| `.emptyResponse` | Nil envelope or `success: false` |
| `.unknown` | All other errors |

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; vehicles fetched from backend on demand.

## Open Questions / TODO

- Add PERSON/COMPANY dedup policy when clarified.
- Integrate real Biluppgifter provider via `VEHICLE_PROVIDER` env var.
- Display vehicle list in UI (garage screen).
