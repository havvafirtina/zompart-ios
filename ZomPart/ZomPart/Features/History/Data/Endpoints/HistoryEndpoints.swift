//
//  HistoryEndpoints.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

private let kScanGetPath = "/functions/v1/scan-get"

// ─────────────────────────────────────────
// MARK: - Single scan
// ─────────────────────────────────────────

struct ScanGetSingleRequest: RequestProtocol {
        typealias EndpointType = ScanGetSingleEndpoint
        let scanId: String
        func toEndpoint() -> ScanGetSingleEndpoint { ScanGetSingleEndpoint(scanId: scanId) }
}

/// GET `/functions/v1/scan-get?scanId={uuid}`
struct ScanGetSingleEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<ScanDetailDataDTO>
        let scanId: String
        var path: String { kScanGetPath }
        var method: HTTPMethod { .get }
        var payload: Encodable? { nil }
        var queryParameters: [String: String]? { ["scanId": scanId] }
}

// ─────────────────────────────────────────
// MARK: - History list
// ─────────────────────────────────────────

struct ScanGetHistoryRequest: RequestProtocol {
        typealias EndpointType = ScanGetHistoryEndpoint
        let vehicleId: String?
        let limit: Int
        let offset: Int
        func toEndpoint() -> ScanGetHistoryEndpoint {
                ScanGetHistoryEndpoint(vehicleId: vehicleId, limit: limit, offset: offset)
        }
}

/// GET `/functions/v1/scan-get?action=history[&vehicle_id=uuid][&limit=n][&offset=n]`
struct ScanGetHistoryEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<HistoryListDataDTO>
        let vehicleId: String?
        let limit: Int
        let offset: Int
        var path: String { kScanGetPath }
        var method: HTTPMethod { .get }
        var payload: Encodable? { nil }
        var queryParameters: [String: String]? {
                var params: [String: String] = [
                        "action": "history",
                        "limit": String(limit),
                        "offset": String(offset)
                ]
                if let vehicleId { params["vehicle_id"] = vehicleId }
                return params
        }
}
