# Catalog Module

TecDoc catalog browsing for a garage vehicle (assembly-group tree → articles) and
part/OE-number search. Backed by the backend proxies `POST /functions/v1/vehicle-parts`
and `POST /functions/v1/parts-search` (see backend `docs/Catalog_API.md`). The backend is a
strict **no-cache proxy** — every call is a live TecDoc request, so the UI never polls or
auto-refreshes and search runs on explicit submit only.

## Structure

- `CatalogModule.swift` — `enum` factory (`makeCatalogRepository`, `makeCatalogBrowseViewModel`,
  `makeCatalogArticlesViewModel`, `makePartsSearchViewModel`) + `CatalogError.localizedMessage`.
- `Data/Endpoints/CatalogEndpoints.swift` — `VehiclePartsCategoriesEndpoint` (body
  `{vehicle_id}` → tree), `VehiclePartsArticlesEndpoint` (body `{vehicle_id, category_id}` →
  articles), `PartsSearchEndpoint` (body `{article_number, vehicle_id?}`; `country_code`
  omitted → backend defaults SE). All POST, 60 s timeout (live TecDoc).
- `Data/DTOs/CatalogDTOs.swift` — `CatalogCategoryDTO` (`id`, `name`, `parent_id`,
  `article_count`; null-id rows dropped in mapping), `CatalogPartSummaryDTO` (the shared
  SelectedPartSummary shape incl. `generic_article_id`, `article_criteria`,
  `fitment_confirmed`), page DTOs (`CatalogCategoriesDataDTO`, `CatalogArticlesDataDTO`,
  `PartsSearchDataDTO`).
- `Data/Repositories/CatalogRepository.swift` — `actor`; maps `HTTPClientError` →
  `CatalogError`.
- `Domain/` — `CatalogCategoryPageDomain` (flat list + `children(of:)` / `isLeaf` client-side
  nesting), `CatalogPartSummaryDomain`, `CatalogArticleCriterionDomain`, page models,
  `CatalogError`.
- `Presentation/` — `CatalogBrowseView` (sheet root with its own `NavigationStack`; routes:
  `.node` drill-down, `.articles` leaf, `.search`), `CatalogArticlesView`, `PartsSearchView`,
  `CatalogPartRowView`. ViewModels are `@Observable @MainActor`, created per screen via
  `@State` (the sheet owns their lifetime; no `ViewModelCache` involvement).

## Entry point

`VehicleDetailView` → "Browse parts catalog" card → `.sheet { CatalogBrowseView(env:vehicleId:) }`.
Only meaningful for plate-resolved vehicles carrying a `tecdoc_ktype`; others surface
`CatalogError.catalogUnavailable` ("Catalog data isn't available for this vehicle.").

## Contract notes (verified against backend source 2026-07-07)

- The category tree arrives FLAT with `parent_id` links; the client nests. Top level =
  `parent_id == null`. Rows with `id == null` cannot be drilled into and are dropped.
- `article_criteria` items: `criteria_id: Int?` (nullable despite the contract table),
  `label: String`, `value: String` (always a string), `unit: String?`, max 12 server-side.
- TecDoc text language follows `Accept-Language` (licensed set da/fi/no/sv; en/tr fall back
  to the country language). No explicit `lang` is sent.

## Error handling

| `HTTPClientError` | `CatalogError` |
|---|---|
| `.notFound` | `.vehicleNotFound` |
| `.clientError(429, data)` | `.rateLimitExceeded(retryAfter:)` (from `meta.retry_after`) |
| 4xx `COUNTRY_NOT_SUPPORTED` | `.countryNotSupported` |
| 4xx `CATALOG_LOOKUP_FAILED` (no carId / no usable data) | `.catalogUnavailable` |
| `.serverError` (502 `TECDOC_LOOKUP_FAILED`, 503 `PROVIDER_UNAVAILABLE`) | `.catalogUnavailable` |
| `.unauthorized` | `.tokenExpired` |
| connectivity cases | `.network` |
| everything else | `.unknown` |

## Compliance

Every catalog screen ends with the contractual `TecDocAttributionFooter` (TecAlliance license:
"TecDoc Inside" + copyright wherever TecDoc data is displayed). The footer is text-only until
the official artwork lands in `Assets.xcassets`.

## Tests

`ZomPartTests/CatalogTreeTests.swift` — flat-tree nesting (`children(of:)`, `isLeaf`), null-id
drop; `PartSummaryDecodingTests` covers the `CatalogPartSummaryDTO` copy.
