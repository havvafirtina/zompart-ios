# Layer 1 Canonical Fields — iOS Integration

*iOS-side audit trail + remaining UI roadmap for Layer 1 (parts identification + OEM resolution).*

> **Scope of this file:** What the backend returns, which iOS files were wired to consume it, and what UI work is still pending. **For backend internals (strategies, AI bridges, endpoint shapes), read the Obsidian vault** — `10_katman_1_parca_esleme_oem_implementation_plan.md`, `12_katman_1_api_reference_ve_ios_contract.md`, and especially `13_scan_flows_source_of_truth.md`.

---

## 1. What Backend Now Returns

Every endpoint that surfaces a `part` summary (`scan-process`, `scan-offers`, `scan-get`, `scan-get?action=history`) returns this shape. All Layer 1 fields are **optional** — older callers that ignore them keep working.

```json
"part": {
  "id": "uuid",
  "name": "Brake Pad",
  "name_tr": "Fren Balatası",
  "name_sv": "Bromsbelägg",
  "part_number": "0986424815",
  "thumbnail_url": "https://fsn1.your-objectstorage.com/tecdoc2025/.../brake-pad.webp",
  "oem_number": "34216761252",
  "mpn": "0986424815",
  "ean": "5902198839491",
  "brand": "Bosch",
  "manufacturer": "BMW",
  "cross_references": ["0986424815", "BP1234", "34216761252"],
  "category_tecdoc": "Brake Pad Set",
  "vehicle_compatible": true,
  "image_url": "https://fsn1.your-objectstorage.com/tecdoc2025/.../brake-pad.webp",
  "confidence_score": 0.9
}
```

`thumbnail_url` is preserved as a legacy alias and now mirrors `image_url`. Use the domain model's `displayImageUrl` accessor (prefers `imageUrl`, falls back to `thumbnailUrl`).

`scan-offers` also exposes three new optional fields on each `Offer`: `sku`, `gtin`, `merchant_id`.

### Field meanings (quick reference)

| Field | Type | What it means |
|---|---|---|
| `oem_number` | `String?` | Canonical OE part number (the vehicle manufacturer's part code, e.g. BMW `34216761252`) |
| `mpn` | `String?` | Manufacturer Part Number from the aftermarket brand (e.g. Bosch `0986424815`) |
| `ean` | `String?` | EAN/GTIN barcode (13-digit usually) — primary key for vendor-side matching |
| `brand` | `String?` | Aftermarket brand (e.g. `Bosch`, `HART`) |
| `manufacturer` | `String?` | OE vehicle manufacturer (e.g. `BMW`, `HYUNDAI`) |
| `cross_references` | `[String]?` | All equivalent part numbers across OEM + aftermarket suppliers |
| `category_tecdoc` | `String?` | TecDoc generic article category (e.g. `Shock Absorber`) |
| `vehicle_compatible` | `Bool?` | `true` if Autodoc Article Details' `articleOemNo[].oemBrand` matched the user's vehicle make; `false` if it explicitly did not; `nil` when not checked |
| `image_url` | `String?` | TecDoc CDN image URL of the part (the trust signal asset) |
| `confidence_score` | `Double?` | AI's overall confidence (0..1) for the CONFIDENT branch |

---

## 2. Files Changed (iOS)

### Data layer — DTOs

| File | Change |
|---|---|
| `ZomPart/ZomPart/Features/Scan/Data/DTOs/ScanDTOs.swift` | `ScanPartSummaryDTO` got 10 new optional fields + CodingKeys. `toModel()` forwards all of them. |
| `ZomPart/ZomPart/Features/Offer/Data/DTOs/OfferDTOs.swift` | `OfferPartSummaryDTO` got the same 10 fields. `OfferItemDTO` got `sku`, `gtin`, `merchantId`. |
| `ZomPart/ZomPart/Features/History/Data/DTOs/HistoryDTOs.swift` | `HistoryPartSummaryDTO` got the same 10 fields. |

### Domain layer — Models

| File | Change |
|---|---|
| `ZomPart/ZomPart/Features/Scan/Domain/Models/ScanProcessResultDomain.swift` | `ScanPartSummaryDomain` got the 10 fields, conforms to `Hashable` (needed by router enum), exposes `displayImageUrl` computed property. |
| `ZomPart/ZomPart/Features/Offer/Domain/Models/OfferDomain.swift` | `OfferDomain` got `sku`, `gtin`, `merchantId`. `OfferPartSummaryDomain` got the 10 fields + `localizedName` + `displayImageUrl`. |
| `ZomPart/ZomPart/Features/History/Domain/Models/HistorySharedDomain.swift` | `HistoryPartSummaryDomain` mirrors the Scan/Offer shape with the same accessors. |

> **Domain mirroring convention:** Scan / Offer / History each define their own `*PartSummaryDomain`. Feature isolation forbids cross-feature imports (per CLAUDE.md), so all three must be kept in sync when Layer 1 evolves. There is no shared module for this — duplication is intentional.

### Navigation

| File | Change |
|---|---|
| `ZomPart/ZomPart/Core/Navigation/AppRouter.swift` | `ScanRoute.scanResult` now carries `part: ScanPartSummaryDomain` instead of separate `partName: String` + `partNumber: String`. |
| `ZomPart/ZomPart/Core/Navigation/MainTabView.swift` | Three call sites updated: the route construction in `handleProcessResult` (2 paths) + the route handler that builds `ScanResultView`. |

### Presentation

| File | Change |
|---|---|
| `ZomPart/ZomPart/Features/Scan/Presentation/Screens/ScanResult/ScanResultView.swift` | Signature: `(part: ScanPartSummaryDomain, onViewOffers: () -> Void)`. Now renders `AsyncImage` from `part.displayImageUrl` (falls back to the legacy success seal on missing/failed image). Shows a manufacturer · brand badge below the part name when both are known. Shows a warning banner when `vehicleCompatible == false`. |

---

## 3. What's Done vs Open (the next session's UI work)

### ✅ Done

**Initial canonical-fields round:**
- All DTOs + Domain models accept the new shape with no breaking changes.
- `Hashable` conformance on `ScanPartSummaryDomain` so navigation routes work.
- Two high-value UI surfaces wired on `ScanResultView`:
  - **Part image** (trust signal — "AI really identified this part").
  - **Vehicle-compatibility warning** when `vehicleCompatible == false` (safety-critical).
  - Manufacturer · brand badge.

**Subsequent UX rounds:**
- **Mode-aware `ScanInputView`** — `ScanInputMode` enum (`.photo` / `.text`) carried through the ViewModel; photo mode shows camera + gallery + OCR, text mode shows a single text field. `input_type` locked at entry, not derived from photo-array state at submit time.
- **`ScanFailedView`** — terminal recovery UI for backend-FAILED scans; `Retry` + `Search by Text` buttons that re-enter the appropriate scan input route.
- **Auth bootstrap fix** — fresh-install detection clears stale Keychain tokens (iOS Keychain survives app delete); `ZomPartAuthTokenProvider` fires `onAuthInvalidated` on refresh failure so `AuthStateManager` routes back to login instead of leaving the UI stuck on MainTabView.

### ⏳ Open (iOS UI session candidates)

Roughly in expected-value order. None are blocked by backend.

1. **OffersListView** — show `part.displayImageUrl` at the top so the user keeps seeing the visual confirmation through the funnel. `OfferPartSummaryDomain` already carries it.
2. **OffersListView part header** — surface `manufacturer`, `brand`, `categoryTecdoc` (chip/breadcrumb) instead of plain `name + partNumber`. Improves perceived precision.
3. **Compatibility warning on OffersListView** — same `vehicleCompatible == false` banner. Currently only shown on ScanResultView; user might navigate straight past it.
4. **Detail/info sheet** — `oemNumber`, `mpn`, `ean`, `crossReferences` are good content for a "More details" sheet or expanded card.
5. **History list + detail** — `HistoryPartSummaryDomain` already carries everything; the cells/screens currently only show `name + partNumber + thumbnailUrl`. Image + brand makes the list much more scannable.
6. **`confidenceScore < 0.85` UI** — consider a soft hint ("low confidence — try a closer photo"). Threshold is a product decision.

> Backend now enriches the AMBIGUOUS path too: when the user picks an alternative via `scan-feedback` (action `SELECT_PART`), the chosen candidate is promoted to CONFIDENT with full canonical fields. iOS already deserializes everything, no additional work needed for this path.

### i18n strings to add

`ScanResultView` currently inlines an English string for the compatibility warning with a `TODO i18n` comment. Suggested `Localizable.xcstrings` keys:

| Key | Default (en) | Notes |
|---|---|---|
| `scan.compatibilityWarning` | `This part may not fit your vehicle. Double-check the OEM number before purchasing.` | Shown when `vehicleCompatible == false` |
| `scan.manufacturerBrandFormat` | `%1$@ · %2$@` | Currently hard-coded format; localize for RTL etc. |

---

## 4. Build & Test

### Build

Same as before — no new SPM dependencies introduced. Xcode resolves on open:

```bash
xcodebuild -project ZomPart/ZomPart.xcodeproj -scheme ZomPart \
  -sdk iphonesimulator -configuration Debug build
```

SourceKit may warn `No such module 'SBNetworking'` / `'SBDesignSystem'` until SPM resolves — those are spurious in the editor's diagnostic stream, not build errors.

### End-to-End Test Recipe

Provider config decides how much external quota gets burned. Pick by goal.

| Goal | `supabase/functions/.env` | Per-scan external cost |
|---|---|---|
| **Smoke test the UI shape** | `AI_PROVIDER=mock`, `PARTS_PROVIDER=mock`, `OFFERS_PROVIDER=mock` | 0 |
| **Real AI, fake parts catalog** | `AI_PROVIDER=gemini`, `PARTS_PROVIDER=mock`, `OFFERS_PROVIDER=mock` | 1 Gemini call |
| **Full Layer 1 live** | `AI_PROVIDER=gemini`, `PARTS_PROVIDER=rapidapi-autodoc`, `OFFERS_PROVIDER=mock` | 1 Gemini + 2 RapidAPI |

Mock fixtures populate **every** new field (image_url, vehicle_compatible=true, etc.), so the UI's loading paths and conditional banners can be exercised without spending quota.

To force the `vehicleCompatible == false` banner with the mock provider, you'd need to temporarily edit `supabase/functions/_shared/providers/parts/mock.ts` (set `vehicle_compatible: false` in the fixture) — that's the cheapest way to verify the warning rendering.

### Local Supabase + iOS

1. Backend running: `supabase start && supabase functions serve`
2. iOS env: `Local.xcconfig` (`SUPABASE_URL=http://127.0.0.1:54321`)
3. Simulator/device on the same network as the Mac.
4. Flow: Auth → add vehicle (vehicle-resolve) → scan part (camera or text) → scan-process → ScanResultView (now with image + optional warning) → offers.

---

## 5. Backend Provider Internals

Backend-side implementation (Autodoc endpoints, AI bridges, vehicle resolver tiers, composite confidence formula, telemetry columns) lives in the Obsidian vault — they are the authoritative source for backend behavior:

- `10_katman_1_parca_esleme_oem_implementation_plan.md` — Layer 1 implementation plan
- `12_katman_1_api_reference_ve_ios_contract.md` — endpoint catalog + iOS contract
- `13_scan_flows_source_of_truth.md` — end-to-end scan flows, state machine, every endpoint's request/response shape

If something here disagrees with the Obsidian docs or the Supabase source, **trust the Supabase source first, then the Obsidian docs, then this file**.

---

## 6. Known Limitations & Gotchas

- **`vehicle_compatible` can be `nil`** when the part candidate's TecDoc data has no compatibility info (or for parts resolved without a `tecdoc_ktype`). Treat `nil` as "no information" — never as `true` or `false`.
- **`cross_references`** is jsonb on the server, decoded as `[String]?` on iOS. Could be a long array (hundreds of entries for popular parts). When you build a UI for it, paginate or truncate.
- **`confidenceScore`** is a composite score (0..1) combining the provider strategy bucket with confirming signals (cross-ref count, image presence, compat check, EAN/MPN). It is _not_ a calibrated probability — use it for UI cutoffs ("show alternatives below X"), not for absolute claims.
- **Layer 2 (offers) still mock.** `OFFERS_PROVIDER=mock` is the only fully working option; the eBay + Awin Bildelaronline providers are stubs. Real offer integration is the next backend sprint, tracked in `11_katman_2_...md`.

---

## 7. Quick-Glance File Map

```
zompart-ios/
├── Docs/
│   └── LAYER1_CANONICAL_FIELDS.md          ← this file
├── ZomPart/ZomPart/
│   ├── Core/
│   │   ├── Auth/
│   │   │   └── AuthStateManager.swift       ← fresh-install detection + handleAuthInvalidated
│   │   ├── Navigation/
│   │   │   ├── AppRouter.swift              ← ScanRoute.scanResult carries part summary; .scanFailed added
│   │   │   └── MainTabView.swift            ← scanResult/scanFailed routing + handleProcessResult
│   │   └── Networking/
│   │       └── ZomPartAuthTokenProvider.swift  ← onAuthInvalidated callback (fired on refresh failure)
│   └── Features/
│       ├── Scan/
│       │   ├── Data/DTOs/ScanDTOs.swift     ← ScanPartSummaryDTO +10 fields
│       │   ├── Domain/Models/
│       │   │   ├── ScanDomain.swift                       ← ScanInputMode enum (.photo / .text)
│       │   │   └── ScanProcessResultDomain.swift          ← Domain +10 fields + Hashable + displayImageUrl
│       │   └── Presentation/Screens/
│       │       ├── ScanInput/ScanInputView.swift          ← mode-conditional UI
│       │       ├── ScanInput/ScanInputViewModel.swift     ← mode locks input_type
│       │       ├── ScanResult/ScanResultView.swift        ← AsyncImage + compat warning + brand badge
│       │       └── ScanFailed/ScanFailedView.swift        ← Retry / Search by Text recovery
│       ├── Offer/
│       │   ├── Data/DTOs/OfferDTOs.swift    ← OfferPartSummaryDTO +10, OfferItemDTO +3
│       │   └── Domain/Models/OfferDomain.swift  ← OfferDomain +3, OfferPartSummaryDomain +10
│       └── History/
│           ├── Data/DTOs/HistoryDTOs.swift   ← HistoryPartSummaryDTO +10
│           └── Domain/Models/HistorySharedDomain.swift  ← HistoryPartSummaryDomain +10
```
