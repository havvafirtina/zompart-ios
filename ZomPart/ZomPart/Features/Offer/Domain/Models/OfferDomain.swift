//
//  OfferDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct OfferDomain: Equatable, Sendable {
    let id: String
    let vendorName: String
    let vendorSlug: String
    let vendorLogoUrl: String?
    let price: Double
    let formattedPrice: String
    let currency: String
    let deliveryDays: Int?
    let deliveryLabel: String?
    let url: String
    let isSponsored: Bool
    let isAvailable: Bool
    let stockLabel: String?
    let rating: Double?
    let ratingCount: Int?
    let sourceProvider: String
    /// Vendor-specific item id (eBay legacyItemId, Awin aw_product_id).
    let sku: String?
    /// EAN/GTIN of the offered product. Use to confirm the offer matches the
    /// canonical part's `ean` before redirecting the user.
    let gtin: String?
    /// Affiliate merchant id (e.g. Awin advertiser id `8988` for Bildelaronline).
    let merchantId: String?
    /// Listing expiry (vendor-supplied when available; usually nil for eBay & Awin feeds).
    let expiresAt: Date?
    /// Opaque provider telemetry — pass-through for analytics, not currently rendered.
    let affiliateMetadata: AffiliateMetadataDomain?

    /// Maps `sourceProvider` to the localizable label key shown in the
    /// "via {provider}" badge. Returns nil for unknown or DEBUG-only
    /// providers in release builds.
    var providerLabelKey: Localized.Offers? {
        switch sourceProvider {
        case "ebay-browse":         return .providerEbayDE
        case "awin-bildelaronline": return .providerBildelaronline
        case "mock":
            #if DEBUG
            return .providerMock
            #else
            return nil
            #endif
        default:
            return nil
        }
    }
}

/// Provider-specific identifiers attached to an offer. Opaque to the UI,
/// pass-through for analytics. New providers can extend the wire shape
/// without an iOS deploy thanks to optional decoding.
struct AffiliateMetadataDomain: Equatable, Sendable {
    let ebayItemId: String?
    let ebayMarketplace: String?
    let awinMerchantId: String?
    let awinFeedSyncedAt: String?
}

enum OfferSortDomain: String, Encodable, Sendable {
    case recommended
    case cheapest
    case fastest
}

/// Shared part summary shape returned by scan-offers.
/// Defined independently here; Offer feature must not import Scan feature.
/// Mirrors `ScanPartSummaryDomain` deliberately — keep both in sync when Layer 1 evolves.
struct OfferPartSummaryDomain: Equatable, Sendable {
    let id: String
    let name: String
    let nameTr: String?
    let nameSv: String?
    let partNumber: String
    let thumbnailUrl: String?
    // Layer 1 canonical enrichment
    let oemNumber: String?
    let mpn: String?
    let ean: String?
    let brand: String?
    let manufacturer: String?
    let crossReferences: [String]?
    let categoryTecdoc: String?
    let vehicleCompatible: Bool?
    let imageUrl: String?
    let confidenceScore: Double?

    var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier
        switch lang {
        case "tr": return nameTr ?? name
        case "sv": return nameSv ?? name
        default: return name
        }
    }

    var displayImageUrl: String? {
        imageUrl ?? thumbnailUrl
    }
}
