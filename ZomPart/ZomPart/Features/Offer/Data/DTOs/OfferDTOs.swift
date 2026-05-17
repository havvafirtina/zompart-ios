//
//  OfferDTOs.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - Shared part summary

struct OfferPartSummaryDTO: Decodable, Sendable {
        let id: String
        let name: String
        let partNumber: String
        let thumbnailUrl: String?

        private enum CodingKeys: String, CodingKey {
                case id, name
                case partNumber = "part_number"
                case thumbnailUrl = "thumbnail_url"
        }

        func toModel() -> OfferPartSummaryDomain {
                OfferPartSummaryDomain(id: id, name: name, partNumber: partNumber, thumbnailUrl: thumbnailUrl)
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
        let isAvailable: Bool
        let stockLabel: String?
        let rating: Double?
        let ratingCount: Int?
        let sourceProvider: String

        private enum CodingKeys: String, CodingKey {
                case id, url, currency, rating
                case vendorName    = "vendor_name"
                case vendorSlug    = "vendor_slug"
                case vendorLogoUrl = "vendor_logo_url"
                case price
                case formattedPrice = "formatted_price"
                case deliveryDays  = "delivery_days"
                case deliveryLabel = "delivery_label"
                case isSponsored   = "is_sponsored"
                case isAvailable   = "is_available"
                case stockLabel    = "stock_label"
                case ratingCount   = "rating_count"
                case sourceProvider = "source_provider"
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
                        isAvailable: isAvailable,
                        stockLabel: stockLabel,
                        rating: rating,
                        ratingCount: ratingCount,
                        sourceProvider: sourceProvider
                )
        }
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
