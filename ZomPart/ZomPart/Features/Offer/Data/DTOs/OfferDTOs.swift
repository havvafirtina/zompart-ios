//
//  OfferDTOs.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - Shared part summary

struct OfferArticleCriterionDTO: Decodable, Sendable {
    /// TecDoc criterion id — nullable on the wire despite the contract table.
    let criteriaId: Int?
    let label: String
    /// Always a string on the wire (`formattedValue ?? rawValue`).
    let value: String
    let unit: String?

    private enum CodingKeys: String, CodingKey {
        case criteriaId = "criteria_id"
        case label, value, unit
    }

    func toModel() -> OfferArticleCriterionDomain {
        OfferArticleCriterionDomain(criteriaId: criteriaId, label: label, value: value, unit: unit)
    }
}

struct OfferPartSummaryDTO: Decodable, Sendable {
    let id: String
    let name: String
    let nameTr: String?
    let nameSv: String?
    let partNumber: String
    let thumbnailUrl: String?
    // Layer 1 canonical enrichment — same shape as ScanPartSummaryDTO.
    // Kept in sync intentionally so the iOS Scan and Offer features stay decoupled
    // (no cross-feature imports) but display the same data.
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
    // TecDoc identification enrichment (additive 2026-07 — optional so rows
    // predating the backend cutover keep decoding).
    let genericArticleId: Int?
    let articleCriteria: [OfferArticleCriterionDTO]?
    let fitmentConfirmed: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, name, brand, manufacturer, mpn, ean
        case nameTr = "name_tr"
        case nameSv = "name_sv"
        case partNumber = "part_number"
        case thumbnailUrl = "thumbnail_url"
        case oemNumber = "oem_number"
        case crossReferences = "cross_references"
        case categoryTecdoc = "category_tecdoc"
        case vehicleCompatible = "vehicle_compatible"
        case imageUrl = "image_url"
        case confidenceScore = "confidence_score"
        case genericArticleId = "generic_article_id"
        case articleCriteria = "article_criteria"
        case fitmentConfirmed = "fitment_confirmed"
    }

    func toModel() -> OfferPartSummaryDomain {
        OfferPartSummaryDomain(
            id: id,
            name: name,
            nameTr: nameTr,
            nameSv: nameSv,
            partNumber: partNumber,
            thumbnailUrl: thumbnailUrl,
            oemNumber: oemNumber,
            mpn: mpn,
            ean: ean,
            brand: brand,
            manufacturer: manufacturer,
            crossReferences: crossReferences,
            categoryTecdoc: categoryTecdoc,
            vehicleCompatible: vehicleCompatible,
            imageUrl: imageUrl,
            confidenceScore: confidenceScore,
            genericArticleId: genericArticleId,
            articleCriteria: (articleCriteria ?? []).map { $0.toModel() },
            fitmentConfirmed: fitmentConfirmed ?? false
        )
    }
}

// MARK: - Affiliate metadata (provider-specific telemetry)

/// Forward-compatible bag of provider-specific identifiers attached to an
/// offer. Decodable ignores unknown keys, so new providers can extend the
/// shape without an iOS deploy.
struct AffiliateMetadataDTO: Decodable, Sendable, Equatable {
    let ebayItemId: String?
    let ebayMarketplace: String?
    /// Marketplace listing title — shown as the offer subtitle so the user
    /// sees what the listing actually is (incl. generation, e.g. "Sorento I")
    /// before tapping out.
    let ebayTitle: String?
    let awinMerchantId: String?
    let awinFeedSyncedAt: String?

    private enum CodingKeys: String, CodingKey {
        case ebayItemId       = "ebay_item_id"
        case ebayMarketplace  = "ebay_marketplace"
        case ebayTitle        = "ebay_title"
        case awinMerchantId   = "awin_merchant_id"
        case awinFeedSyncedAt = "awin_feed_synced_at"
    }

    func toModel() -> AffiliateMetadataDomain {
        AffiliateMetadataDomain(
            ebayItemId: ebayItemId,
            ebayMarketplace: ebayMarketplace,
            ebayTitle: ebayTitle,
            awinMerchantId: awinMerchantId,
            awinFeedSyncedAt: awinFeedSyncedAt
        )
    }
}

// MARK: - Offer item

struct OfferItemDTO: Decodable, Sendable {
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
    /// Disclosure flag — true when the outbound URL is commission-monetized
    /// (eBay EPN, Awin). Optional: absent on offers stored before 2026-07-06.
    let isAffiliate: Bool?
    let isAvailable: Bool
    let stockLabel: String?
    let rating: Double?
    let ratingCount: Int?
    let sourceProvider: String
    // Layer 2 vendor identifiers (optional). Useful for client-side cross-check
    // and analytics, not necessarily shown in UI.
    let sku: String?
    let gtin: String?
    let merchantId: String?
    // Wire-format ISO 8601 string; Domain layer exposes a parsed `Date?`.
    let expiresAt: String?
    let affiliateMetadata: AffiliateMetadataDTO?

    private enum CodingKeys: String, CodingKey {
        case id, url, currency, rating, sku, gtin
        case vendorName    = "vendor_name"
        case vendorSlug    = "vendor_slug"
        case vendorLogoUrl = "vendor_logo_url"
        case price
        case formattedPrice = "formatted_price"
        case deliveryDays  = "delivery_days"
        case deliveryLabel = "delivery_label"
        case isSponsored   = "is_sponsored"
        case isAffiliate   = "is_affiliate"
        case isAvailable   = "is_available"
        case stockLabel    = "stock_label"
        case ratingCount   = "rating_count"
        case sourceProvider = "source_provider"
        case merchantId    = "merchant_id"
        case expiresAt     = "expires_at"
        case affiliateMetadata = "affiliate_metadata"
    }

    func toModel() -> OfferDomain {
        OfferDomain(
            id: id,
            vendorName: vendorName,
            vendorSlug: vendorSlug,
            vendorLogoUrl: vendorLogoUrl,
            price: price,
            formattedPrice: formattedPrice,
            currency: currency,
            deliveryDays: deliveryDays,
            deliveryLabel: deliveryLabel,
            url: url,
            isSponsored: isSponsored,
            isAffiliate: isAffiliate ?? false,
            isAvailable: isAvailable,
            stockLabel: stockLabel,
            rating: rating,
            ratingCount: ratingCount,
            sourceProvider: sourceProvider,
            sku: sku,
            gtin: gtin,
            merchantId: merchantId,
            expiresAt: expiresAt.flatMap(OfferItemDTO.parseDate),
            affiliateMetadata: affiliateMetadata?.toModel()
        )
    }

    /// Supabase timestamptz usually carries fractional seconds, but emits
    /// none when they are exactly zero — try both formats.
    private static func parseDate(_ string: String) -> Date? {
        iso8601.date(from: string) ?? iso8601NoFraction.date(from: string)
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601NoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - scan-offers data DTO

struct ScanOffersDataDTO: ResponseProtocol {
    typealias ModelType = OfferListDomain

    let scanId: String
    let part: OfferPartSummaryDTO?
    let offers: [OfferItemDTO]
    let sortApplied: String
    let totalCount: Int

    private enum CodingKeys: String, CodingKey {
        case scanId      = "scan_id"
        case part, offers
        case sortApplied = "sort_applied"
        case totalCount  = "total_count"
    }

    func toModel() -> OfferListDomain {
        OfferListDomain(
            scanId: scanId,
            part: part?.toModel(),
            offers: offers.map { $0.toModel() },
            sortApplied: OfferSortDomain(rawValue: sortApplied) ?? .recommended,
            totalCount: totalCount
        )
    }
}

// MARK: - offers-click data DTO

struct OffersClickDataDTO: ResponseProtocol {
    typealias ModelType = OfferClickResultDomain

    let clickId: String
    let offerId: String
    let scanId: String
    let redirectUrl: String
    let tracked: Bool

    private enum CodingKeys: String, CodingKey {
        case clickId    = "click_id"
        case offerId    = "offer_id"
        case scanId     = "scan_id"
        case redirectUrl = "redirect_url"
        case tracked
    }

    func toModel() -> OfferClickResultDomain {
        OfferClickResultDomain(
            clickId: clickId,
            offerId: offerId,
            scanId: scanId,
            redirectUrl: redirectUrl,
            tracked: tracked
        )
    }
}
