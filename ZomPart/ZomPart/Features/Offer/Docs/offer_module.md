# Offer Module

## Responsibilities

- List vendor offers for a scan via the `scan-offers` edge function.
- Re-sort the fetched offers client-side (recommended / cheapest / fastest) without a refetch.
- Record an offer click via `offers-click` and open the resulting (UTM-tracked) redirect URL,
  routing web URLs to an in-app Safari sheet and non-web URLs to the system.

## Public Contracts

- Domain Interface: `OfferRepositoryProtocol` (`Sendable`)
  - `listOffers(scanId: String, sort: OfferSortDomain) async throws -> OfferListDomain`
  - `recordClick(offerId: String, scanId: String) async throws -> OfferClickResultDomain`
- Presentation: `OffersListViewModel` (`@Observable`, `@MainActor`), `OffersListView`, `OfferCardView`.
- Factory: `OfferModule.makeOfferRepository(httpClient:)`, `OfferModule.makeOffersListViewModel(env:scanId:)`.
- `OfferError.localizedMessage` (an extension defined in `OfferModule.swift`) maps the feature
  error to a localized UI string.

## Data Dependencies

| Endpoint | Path | Method | Request | Response |
|---|---|---|---|---|
| `scan-offers` | `/functions/v1/scan-offers` | GET | query: `scanId`, `sort` | `APIEnvelope<ScanOffersDataDTO>` |
| `offers-click` | `/functions/v1/offers-click` | POST | body: `offer_id`, `scan_id` | `APIEnvelope<OffersClickDataDTO>` |

- `ScanOffersEndpoint` sends no body (`payload == nil`); it passes `queryParameters`
  `["scanId": scanId, "sort": sort.rawValue]`. Note the query key is camelCase `scanId`.
- `OffersClickEndpoint` POSTs a private `OffersClickBody` whose JSON keys are `offer_id` and `scan_id`.
- `OfferRepository` is an `actor` over `HTTPClient` (implicit `Sendable`). Both methods validate
  `envelope != nil`, `envelope.success`, and `envelope.data != nil`, then return `envelope.toModel()`.

## Domain Models

- `OfferDomain` (`Equatable`, `Sendable`) — `id`, `vendorName`, `vendorSlug`, `vendorLogoUrl`,
  `price` (`Double`), `formattedPrice`, `currency`, `deliveryDays` (`Int?`), `deliveryLabel`,
  `url`, `isSponsored`, `isAffiliate` (disclosure flag — commission-monetized link, eBay EPN /
  Awin; separate concept from `isSponsored`), `isAvailable`, `stockLabel`, `rating` (`Double?`),
  `ratingCount` (`Int?`), `sourceProvider`, `sku`, `gtin`, `merchantId`, `expiresAt` (`Date?`,
  parsed from ISO 8601), `affiliateMetadata` (`AffiliateMetadataDomain?`).
  - Computed `providerLabelKey: Localized.Offers?` — maps `sourceProvider` to a "via {provider}"
    badge key: `ebay-browse` → `.providerEbayDE`, `awin-bildelaronline` → `.providerBildelaronline`,
    `mock` → `.providerMock` (DEBUG builds only; `nil` in release), anything else → `nil`.
- `AffiliateMetadataDomain` (`Equatable`, `Sendable`) — `ebayItemId`, `ebayMarketplace`,
  `awinMerchantId`, `awinFeedSyncedAt` (all `String?`). Opaque provider telemetry; not rendered.
- `OfferSortDomain` (`String`-backed, `Encodable`, `Sendable`) — `.recommended` | `.cheapest` |
  `.fastest`. The raw values match the `sort` query parameter.
- `OfferPartSummaryDomain` (`Equatable`, `Sendable`) — `id`, `name`, `nameTr`, `nameSv`,
  `partNumber`, `thumbnailUrl`, plus Layer-1 canonical fields: `oemNumber`, `mpn`, `ean`, `brand`,
  `manufacturer`, `crossReferences` (`[String]?`), `categoryTecdoc`, `vehicleCompatible` (`Bool?`),
  `imageUrl`, `confidenceScore` (`Double?`), plus TecDoc identification enrichment (2026-07):
  `genericArticleId` (`Int?`), `articleCriteria` (`[OfferArticleCriterionDomain]`),
  `fitmentConfirmed` (`Bool`). Computed: `localizedName` (`tr`/`sv` via
  `Locale.current.language.languageCode`, falling back to `name`) and `displayImageUrl`
  (`imageUrl ?? thumbnailUrl`). Mirrors `ScanPartSummaryDomain` intentionally so Scan and Offer
  stay decoupled (Offer must not import Scan).
- `OfferArticleCriterionDomain` (`Equatable`, `Sendable`) — `criteriaId` (`Int?`, nullable on the
  wire), `label`, `value` (always a `String` on the wire), `unit` (`String?`).
- `OfferListDomain` (`Equatable`, `Sendable`) — `scanId`, `part` (`OfferPartSummaryDomain?`, nil
  when the scan has no selected part yet), `offers` (`[OfferDomain]`), `sortApplied`
  (`OfferSortDomain`), `totalCount` (`Int`).
- `OfferClickResultDomain` (`Equatable`, `Sendable`) — `clickId`, `offerId`, `scanId`,
  `redirectUrl` (UTM-parametrized vendor URL), `tracked` (`Bool`).

## DTO → Domain Mapping

| DTO | Wire keys (snake_case unless noted) | Maps to |
|---|---|---|
| `OfferPartSummaryDTO` | `id`, `name`, `name_tr`, `name_sv`, `part_number`, `thumbnail_url`, `oem_number`, `mpn`, `ean`, `brand`, `manufacturer`, `cross_references`, `category_tecdoc`, `vehicle_compatible`, `image_url`, `confidence_score`, `generic_article_id`, `article_criteria`, `fitment_confirmed` | `OfferPartSummaryDomain` |
| `OfferArticleCriterionDTO` | `criteria_id`, `label`, `value`, `unit` | `OfferArticleCriterionDomain` |
| `AffiliateMetadataDTO` | `ebay_item_id`, `ebay_marketplace`, `awin_merchant_id`, `awin_feed_synced_at` | `AffiliateMetadataDomain` |
| `OfferItemDTO` | `id`, `url`, `currency`, `rating`, `sku`, `gtin`, `vendor_name`, `vendor_slug`, `vendor_logo_url`, `price`, `formatted_price`, `delivery_days`, `delivery_label`, `is_sponsored`, `is_affiliate` (optional → `false`), `is_available`, `stock_label`, `rating_count`, `source_provider`, `merchant_id`, `expires_at`, `affiliate_metadata` | `OfferDomain` |
| `ScanOffersDataDTO` (`ResponseProtocol`) | `scan_id`, `part`, `offers`, `sort_applied`, `total_count` | `OfferListDomain` |
| `OffersClickDataDTO` (`ResponseProtocol`) | `click_id`, `offer_id`, `scan_id`, `redirect_url`, `tracked` | `OfferClickResultDomain` |

Mapping notes:

- `OfferItemDTO.toModel()` parses `expires_at` via `expiresAt.flatMap(OfferItemDTO.parseDate)`.
  `parseDate` tries an ISO 8601 formatter with fractional seconds first, then one without — Supabase
  `timestamptz` omits fractional seconds when they are exactly zero. An unparsable string yields nil.
- `ScanOffersDataDTO.toModel()` decodes `sort_applied` with `OfferSortDomain(rawValue:) ?? .recommended`,
  so an unknown server sort value degrades to `.recommended`.
- `AffiliateMetadataDTO` (and `OfferPartSummaryDTO`) ignore unknown keys, so new provider/enrichment
  fields can ship server-side without an iOS deploy.

## Offers List Flow

1. `MainTabView` resolves the `ScanRoute.offers(scanId:)` destination to `OffersListView`, whose
   ViewModel comes from `ViewModelCache.offersListVM(env:scanId:)` — cached per `scanId` (see
   "ViewModel Caching").
2. `OffersListView.task` calls `viewModel.loadOffers()` only when `state == .idle`, so re-evaluating
   the destination closure does not re-fetch.
3. `loadOffers()` snapshots `allOffers` into `previousOffers`, sets `state = .loading`, then calls
   `offerRepository.listOffers(scanId:sort: .recommended)`. It always requests `.recommended`;
   sorting is applied client-side afterward.
4. On success it stores `part` and `allOffers` from the result and calls `applySort()`.
5. `applySort()` produces the visible `offers` array (see "Sorting Behavior") and sets
   `state = .empty` when the result is empty, otherwise `.loaded(OfferListDomain(...))` rebuilt with
   the current `selectedSort` and `offers.count` as `totalCount`.
6. `changeSort(_:)` is a no-op when the new sort equals `selectedSort`; otherwise it updates
   `selectedSort` and re-runs `applySort()` over the already-fetched `allOffers` (no refetch).

### Cancellation / race handling in `loadOffers()`

`listOffers` may throw `CancellationError` (the repository normalizes both `CancellationError` and
`URLError.cancelled` to `CancellationError`). When `loadOffers()` catches `CancellationError` it
restores `allOffers = previousOffers`; if there were previous offers it re-applies the sort
(returning to the prior loaded view), otherwise it falls back to `state = .idle`. Any `OfferError`
maps to `state = .error(error.localizedMessage)`; any other error maps to
`state = .error(Localized.Error.unknown.localized)`.

## Sorting Behavior

Sorting is applied **client-side** in `OffersListViewModel.applySort()` over `allOffers`.

| Value | Logic |
|---|---|
| `.recommended` | Server order preserved (`offers = allOffers`, no client re-sort) |
| `.cheapest` | Currency-aware (see below) |
| `.fastest` | `deliveryDays` ascending, treating nil as `Int.max` (so unknown delivery sorts last) |

### Currency-aware "cheapest"

Prices in different currencies are not directly comparable (100 SEK is not cheaper than 90 EUR),
so `.cheapest` does not sort by raw price across the whole list. It first counts offers per
`currency`, then sorts so that:

1. within the same currency, lower `price` comes first;
2. across currencies, the currency group with **more** offers (the dominant currency) comes first;
3. ties between equally sized currency groups break by ascending `currency` string.

## Offer Click / Redirect Flow

The card's tap handler calls `viewModel.recordClick(offer:)`:

1. It calls `offerRepository.recordClick(offerId: offer.id, scanId: scanId)` and routes the
   server-supplied `result.redirectUrl` (which carries server-applied UTM params).
2. If `recordClick` throws (any error), it falls back to routing the raw `offer.url`, so the user is
   never blocked when click tracking fails.
3. Routing is scheme-validated in `route(_:)`:
   - a nil `URL` is ignored;
   - `http` / `https` URLs are assigned to `redirectUrl` → presented in an in-app `SafariView` sheet;
   - any other scheme (e.g. `tel:`, `mailto:`, store deeplinks) is assigned to `externalUrl` and
     handed to the system via SwiftUI `openURL`, because `SFSafariViewController` crashes on non-web
     URLs.

Sheet presentation uses `IdentifiableURL`, whose `id` is `url.absoluteString` (not a fresh UUID) so
SwiftUI does not treat each body re-evaluation as a new sheet item and re-present it. `dismissSafari()`
clears `redirectUrl`; `dismissExternalUrl()` clears `externalUrl` after the system handles it.

## Part Summary Header

`OffersListView.partHeader` renders only when `viewModel.part != nil`. It shows two text lines in a
secondary-surface, rounded card: `part.name` (`sbBodySemiboldDefault`) and `part.partNumber`
(`sbBodyRegularSmall`). It does **not** currently use `localizedName` or render
`displayImageUrl` / a thumbnail. The header is the first row of the offers `List` (separator hidden,
clear background, list-row insets `EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)`).

## Offer Card Rendering

`OfferCardView` is a plain-styled `Button` (`onTap`) over a secondary-surface, rounded, soft-shadow
card; overall opacity is `0.4` when `offer.isAvailable == false`, else `1.0`.

- Vendor block: optional `AsyncImage` logo (36×36, placeholder = `sbSurfaceTertiary`) shown only when
  `vendorLogoUrl` is a valid URL; `vendorName`; an optional "via {provider}" badge rendered when
  `providerLabelKey` is non-nil (via `Localized.Offers.viaProvider.localized(label)`); and an optional
  `stockLabel` colored `sbStatusSuccess` when available, `sbStatusError` when not.
- Price block (trailing): `formattedPrice` (`sbTitleSemiboldLarge`, accent color) over `currency`.
- Delivery / rating row: `deliveryLabel` with a `shippingbox.fill` icon when present; a star + `rating`
  (`%.1f`) plus optional `(ratingCount)` when `rating` is present.
- A `sponsored` label is shown when `offer.isSponsored`.
- An `offers.affiliateBadge` label ("Ad · affiliate link") is shown when `offer.isAffiliate`
  (eBay EPN / Awin disclosure — required by programme terms and App Store guidelines).

`OffersListView` additionally renders a one-time commission-disclosure footer
(`offers.affiliateFooter`) under the list whenever at least one offer has `isAffiliate == true`,
and always ends the list with the contractual `TecDocAttributionFooter` (part data is TecDoc).

`sku`, `gtin`, `merchantId`, `expiresAt`, and `affiliateMetadata` are not rendered by the card.

## Error Handling

`OfferError` (`Error`, `Equatable`) cases: `invalidUUID`, `scanNotFound`, `offerNotFound`,
`tokenExpired`, `rateLimitExceeded(retryAfter: Int?)`, `serviceUnavailable`, `network`,
`emptyResponse`, `unknown`. `HTTPClientError` never escapes the repository. The repository has two
mapping functions (`mapListError`, `mapClickError`) that differ only in their `.notFound` result.

| `HTTPClientError` | `mapListError` (scan-offers) | `mapClickError` (offers-click) |
|---|---|---|
| `.notFound` | `.scanNotFound` | `.offerNotFound` |
| `.clientError(statusCode: 429, data)` | `.rateLimitExceeded(retryAfter:)` | `.rateLimitExceeded(retryAfter:)` |
| `.clientError(_, data)` with `INVALID_UUID` code | `.invalidUUID` | `.invalidUUID` |
| `.clientError(_, data)` other/unknown code | `.unknown` | `.unknown` |
| `.serverError` (5xx, incl. 503 PROVIDER_UNAVAILABLE) | `.serviceUnavailable` | `.serviceUnavailable` |
| `.unauthorized` | `.tokenExpired` | `.tokenExpired` |
| `.notConnectedToInternet`, `.networkConnectionLost` | `.network` | `.network` |
| default | `.unknown` | `.unknown` |

Notes:

- `retryAfter` is decoded from the 429 body's `meta.retry_after` (seconds) via
  `APIErrorParser.retryAfterSeconds(from:)`.
- Repository-thrown `OfferError.emptyResponse` is raised when the envelope is nil, `success == false`,
  or `data == nil` — it is re-thrown unchanged (caught as `OfferError` before the `HTTPClientError`
  branch).
- `CancellationError` and `URLError(.cancelled)` are both re-thrown as `CancellationError` and are not
  mapped to an `OfferError`.

### Error → UI string (`OfferError.localizedMessage`)

| Case | Localized string |
|---|---|
| `.scanNotFound` | `Localized.Error.scanNotFound` |
| `.offerNotFound` | `Localized.Offers.errorOfferNotFound` |
| `.tokenExpired` | `Localized.Error.tokenExpired` |
| `.rateLimitExceeded(retryAfter:)` | `Localized.Error.rateLimitRetryIn` (with seconds) or `Localized.Error.rateLimitExceeded` |
| `.serviceUnavailable` | `Localized.Offers.errorServiceUnavailable` |
| `.network` | `Localized.Error.network` |
| default (`.invalidUUID`, `.emptyResponse`, `.unknown`) | `Localized.Error.unknown` |

`OffersListViewModel.loadOffers()` surfaces this string via `state = .error(...)`; `OffersListView`
renders it with a `wifi.slash` icon and a Retry button.

## Empty Offers

`applySort()` sets `state = .empty` when the visible `offers` array is empty (no offers, or all
filtered to nothing). `OffersListView` shows a `tag.slash.fill` empty state with the
`Localized.Offers.empty` message and a Retry button that re-runs `loadOffers()` — offers are produced
asynchronously by the backend after a scan, so an empty first response is normal (not an error) and
the cached ViewModel would otherwise never re-query.

## ViewModel Caching

`ViewModelCache.offersListVM(env:scanId:)` owns `OffersListViewModel` instances keyed by `scanId`,
returning the same instance across `navigationDestination` re-evaluations (so in-flight sort/load
state survives ancestor view updates). The cache is **not** `@Observable`. Offer VMs are evicted by:

- `invalidateHistory()` — clears `offersListVMs` (alongside history/scanDetail caches); called after a
  scan finishes processing.
- `invalidateScanDetail(scanId:)` — removes the offer VM for that `scanId` (called when a
  disambiguation selection changes the scan's part, so offers reload).

`MainTabView` also calls `vmCache.invalidateScanFlow()` when the scan stack pops to root, but that
does not touch offer VMs.

## Routes

- `AppRouter.ScanRoute.offers(scanId: String)` is the only route into this module. It is pushed from
  `ScanResultView` (`onViewOffers`), `ScanDetailView` (`onViewOffers`), and the disambiguation flow
  (`DisambiguationView`'s resolution when `feedback.nextAction == .showOffers`).

## Analytics

- No analytics events defined for this scope. A module-wide search for `Analytics` / `SBAnalytics` /
  `track` finds only comments — `affiliateMetadata`, `sku`, `gtin`, and `merchantId` are decoded as
  pass-through fields described as "for analytics," but no tracking call sites exist.

## Persistence

- No local persistence. Offers are fetched on demand and re-sorted in memory; the per-`scanId`
  ViewModel cache in `ViewModelCache` is the only retention and lives only for the navigation session.

## Open Questions / TODO

- The non-429 `.clientError` mapping collapses all parsed `APIErrorCode`s to `.invalidUUID`; if other
  client-error codes need distinct UI handling, the `switch APIErrorParser.code(...)` branches should
  diverge.
- Surface `expiresAt` / availability cues and the part `displayImageUrl` in the UI when vendor feeds
  provide them.
- Consider offer caching across sessions for better UX on slow connections.
