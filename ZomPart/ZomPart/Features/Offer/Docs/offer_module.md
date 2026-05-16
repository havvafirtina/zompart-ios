# Offer Module

## Responsibilities

- List vendor offers for a scan via `scan-offers` (sorted by recommended / cheapest / fastest).
- Record an offer click and obtain a UTM-tracked redirect URL via `offers-click`.

## Public Contracts

- Domain Interfaces:
  - `OfferRepositoryProtocol`

## Data Dependencies

| Endpoint | Path | Method |
|---|---|---|
| `scan-offers` | `/functions/v1/scan-offers` | GET (query params) |
| `offers-click` | `/functions/v1/offers-click` | POST |

## Domain Models

- `OfferDomain` — id, vendorName, vendorSlug, vendorLogoUrl, price, formattedPrice, currency, deliveryDays, deliveryLabel, url, isSponsored, isAvailable, stockLabel, rating, ratingCount, sourceProvider
- `OfferSortDomain` — `.recommended` | `.cheapest` | `.fastest`
- `OfferPartSummaryDomain` — id, name, partNumber, thumbnailUrl (same shape as `SelectedPartSummary` in backend; defined independently — Offer must not import Scan)
- `OfferListDomain` — scanId, part?, offers, sortApplied, totalCount
- `OfferClickResultDomain` — clickId, offerId, scanId, redirectUrl, tracked

## Sorting Behavior

| Value | Logic |
|---|---|
| `.recommended` | Sponsored first → rating desc → price asc |
| `.cheapest` | Price ascending |
| `.fastest` | Delivery days ascending, nulls last |
| (default) | Falls back to `.recommended` |

## Error Handling

`OfferError` maps `HTTPClientError` cases. `HTTPClient` uses a dedicated `.notFound` case for 404.
Repositories also validate `envelope.success` and `envelope.data != nil` before calling `toModel()`.

| Case | Trigger |
|---|---|
| `.invalidUUID` | 400 — `INVALID_UUID` error code |
| `.scanNotFound` | 404 (`.notFound`) on scan-offers |
| `.offerNotFound` | 404 (`.notFound`) on offers-click |
| `.tokenExpired` | 401 — Bearer token expired (after refresh failure) |
| `.rateLimitExceeded` | 429 |
| `.network` | No connectivity |
| `.emptyResponse` | Nil envelope or `success: false` |
| `.unknown` | All other errors |

## Empty Offers

`listOffers` returns `OfferListDomain` with `offers: []` and `part: nil` when:
- The scan has no selected part yet (DISAMBIGUATION not resolved), or
- The scan has no offers inserted.
This is a valid 200 response, not an error.

## Click Tracking

`recordClick` appends UTM params to the vendor URL server-side:
- `utm_source=bildelar`
- `utm_medium=app`
- `utm_campaign={scan_id}`
- `utm_content={offer_id}`

The client must open `OfferClickResultDomain.redirectUrl` in a browser or SFSafariViewController.

## Analytics

- No analytics events defined for this scope.

## Persistence

- No local persistence; offers are fetched from backend on demand.

## Open Questions / TODO

- Integrate real vendor provider via `OFFERS_PROVIDER` env var (currently mock-only).
- Add offer caching for better UX on slow connections.
