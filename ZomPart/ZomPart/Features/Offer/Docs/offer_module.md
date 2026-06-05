# Offer Module

## Responsibilities

- List vendor offers for a scan via `scan-offers`.
- Re-sort the fetched offers client-side (recommended / cheapest / fastest).
- Record an offer click and open the UTM-tracked redirect URL via `offers-click`.

## Public Contracts

- Domain Interface: `OfferRepositoryProtocol`
  - `listOffers(scanId: String, sort: OfferSortDomain) async throws -> OfferListDomain`
  - `recordClick(offerId: String, scanId: String) async throws -> OfferClickResultDomain`
- Presentation: `OffersListViewModel` (`@Observable`, `@MainActor`), `OffersListView`, `OfferCardView`.
- Factory: `OfferModule.makeOfferRepository(httpClient:)`, `OfferModule.makeOffersListViewModel(env:scanId:)`.

## Data Dependencies

| Endpoint | Path | Method | Request | Response |
|---|---|---|---|---|
| `scan-offers` | `/functions/v1/scan-offers` | GET | query: `scanId`, `sort` | `APIEnvelope<ScanOffersDataDTO>` |
| `offers-click` | `/functions/v1/offers-click` | POST | body: `offer_id`, `scan_id` | `APIEnvelope<OffersClickDataDTO>` |

`OfferRepository` is an `actor` over `HTTPClient`. Both methods validate `envelope.success` and
`envelope.data != nil`, then call `toModel()`.

## Domain Models

- `OfferDomain` — id, vendorName, vendorSlug, vendorLogoUrl, price, formattedPrice, currency,
  deliveryDays, deliveryLabel, url, isSponsored, isAvailable, stockLabel, rating, ratingCount,
  sourceProvider, sku, gtin, merchantId, expiresAt (`Date?`, parsed from ISO 8601), affiliateMetadata.
  - `providerLabelKey: Localized.Offers?` — maps `sourceProvider` to a "via {provider}" badge key
    (`ebay-browse` → providerEbayDE, `awin-bildelaronline` → providerBildelaronline,
    `mock` → providerMock in DEBUG only, else nil).
- `AffiliateMetadataDomain` — ebayItemId, ebayMarketplace, awinMerchantId, awinFeedSyncedAt
  (opaque provider telemetry; decoded from optional keys, not rendered).
- `OfferSortDomain` — `.recommended` | `.cheapest` | `.fastest` (raw values match query param).
- `OfferPartSummaryDomain` — id, name, nameTr, nameSv, partNumber, thumbnailUrl, and Layer-1
  canonical fields: oemNumber, mpn, ean, brand, manufacturer, crossReferences, categoryTecdoc,
  vehicleCompatible, imageUrl, confidenceScore. Computed: `localizedName` (tr/sv/fallback),
  `displayImageUrl` (`imageUrl ?? thumbnailUrl`). Mirrors `ScanPartSummaryDomain`; Offer must not import Scan.
- `OfferListDomain` — scanId, part?, offers, sortApplied, totalCount.
- `OfferClickResultDomain` — clickId, offerId, scanId, redirectUrl, tracked.

## Sorting Behavior

Sorting is applied **client-side** in `OffersListViewModel.applySort()` over the fetched list.
`loadOffers()` always requests `sort: .recommended`; the picker re-sorts locally without a refetch.

| Value | Logic |
|---|---|
| `.recommended` | Server order preserved (no client re-sort) |
| `.cheapest` | Price ascending |
| `.fastest` | `deliveryDays` ascending, nils last (`Int.max`) |

## Error Handling

`OfferError` maps `HTTPClientError`; `HTTPClientError` never escapes the repository.

| Case | Trigger |
|---|---|
| `.scanNotFound` | `.notFound` (404) on `scan-offers` |
| `.offerNotFound` | `.notFound` (404) on `offers-click` |
| `.rateLimitExceeded` | `.clientError` with status 429 |
| `.invalidUUID` | any other `.clientError` (catch-all for client-side status codes) |
| `.tokenExpired` | `.unauthorized` (401, after refresh failure) |
| `.network` | `.notConnectedToInternet` / `.networkConnectionLost` |
| `.emptyResponse` | nil envelope, `success: false`, or nil `data` |
| `.unknown` | all other errors |

`OffersListViewModel.loadOffers()` surfaces a single network error string and treats
`CancellationError` specially (restores previous offers or returns to `.idle`).

## Empty Offers

`applySort()` sets `state = .empty` when the sorted list is empty (no offers or no selected part);
`OffersListView` shows the `tag.slash.fill` empty state. A 200 response with `offers: []` is not an error.

## Click Tracking

`recordClick` returns `OfferClickResultDomain` whose `redirectUrl` carries server-applied UTM params.
The ViewModel opens it in an in-app `SafariView` (sheet). If `recordClick` throws, it falls back to
opening the raw `offer.url` so the user is never blocked.

## Analytics

- No analytics events defined for this scope. `affiliateMetadata`, `sku`, `gtin`, and `merchantId`
  are decoded as pass-through fields for future analytics.

## Persistence

- No local persistence; offers are fetched on demand and re-sorted in memory.

## Open Questions / TODO

- Add offer caching for better UX on slow connections.
- Surface `expiresAt` / availability in the card when vendor feeds provide it.
