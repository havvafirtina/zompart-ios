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
}

enum OfferSortDomain: String, Encodable, Sendable {
    case recommended = "recommended"
    case cheapest    = "cheapest"
    case fastest     = "fastest"
}

/// Shared part summary shape returned by scan-offers.
/// Defined independently here; Offer feature must not import Scan feature.
struct OfferPartSummaryDomain: Equatable, Sendable {
    let id: String
    let name: String
    let partNumber: String
    let thumbnailUrl: String?
}
