//
//  VehicleListEndpoint.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - RequestProtocol

struct VehicleListRequest: RequestProtocol {
        typealias EndpointType = VehicleListEndpoint
        func toEndpoint() -> VehicleListEndpoint { VehicleListEndpoint() }
}

// MARK: - Endpoint

/// GET `/functions/v1/vehicle-resolve` — returns all vehicles in the user's garage.
/// Requires Bearer token.
struct VehicleListEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<VehicleResolveDataDTO>

        var path: String { "/functions/v1/vehicle-resolve" }
        var method: HTTPMethod { .get }
        var payload: Encodable? { nil }
}
