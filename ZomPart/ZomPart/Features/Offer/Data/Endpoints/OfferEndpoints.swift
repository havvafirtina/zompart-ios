//
//  OfferEndpoints.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// ─────────────────────────────────────────
// MARK: - scan-offers (GET)
// ─────────────────────────────────────────

struct ScanOffersRequest: RequestProtocol {
        typealias EndpointType = ScanOffersEndpoint
        let scanId: String
        let sort: OfferSortDomain
        func toEndpoint() -> ScanOffersEndpoint {
                ScanOffersEndpoint(scanId: scanId, sort: sort)
        }
}

/// GET `/functions/v1/scan-offers?scanId={uuid}&sort={value}`
/// Uses query parameters; no request body.
struct ScanOffersEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<ScanOffersDataDTO>
        let scanId: String
        let sort: OfferSortDomain
        var path: String { "/functions/v1/scan-offers" }
        var method: HTTPMethod { .get }
        var payload: Encodable? { nil }
        var queryParameters: [String: String]? {
                ["scanId": scanId, "sort": sort.rawValue]
        }
}

// ─────────────────────────────────────────
// MARK: - offers-click (POST)
// ─────────────────────────────────────────

struct OffersClickRequest: RequestProtocol {
        typealias EndpointType = OffersClickEndpoint
        let offerId: String
        let scanId: String
        func toEndpoint() -> OffersClickEndpoint {
                OffersClickEndpoint(offerId: offerId, scanId: scanId)
        }
}

/// POST `/functions/v1/offers-click`
struct OffersClickEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<OffersClickDataDTO>
        let offerId: String
        let scanId: String
        var path: String { "/functions/v1/offers-click" }
        var method: HTTPMethod { .post }
        var payload: Encodable? { OffersClickBody(offerId: offerId, scanId: scanId) }
}

private struct OffersClickBody: Encodable {
        let offerId: String
        let scanId: String
        private enum CodingKeys: String, CodingKey {
                case offerId = "offer_id"
                case scanId  = "scan_id"
        }
}
