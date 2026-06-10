//
//  VehicleResolveEndpoints.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - Shared path

private let kVehicleResolvePath = "/functions/v1/vehicle-resolve"

// ─────────────────────────────────────────
// MARK: - VIN
// ─────────────────────────────────────────

struct VehicleResolveVINRequest: RequestProtocol {
    typealias EndpointType = VehicleResolveVINEndpoint
    let vin: String
    let countryCode: String
    func toEndpoint() -> VehicleResolveVINEndpoint { VehicleResolveVINEndpoint(vin: vin, countryCode: countryCode) }
}

struct VehicleResolveVINEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<VehicleResolveDataDTO>
    let vin: String
    let countryCode: String
    var path: String { kVehicleResolvePath }
    var method: HTTPMethod { .post }
    var payload: Encodable? { VINBody(resolveType: "VIN", vin: vin, countryCode: countryCode) }
}

private struct VINBody: Encodable {
    let resolveType: String
    let vin: String
    let countryCode: String
    private enum CodingKeys: String, CodingKey {
        case resolveType = "resolve_type"
        case vin
        case countryCode = "country_code"
    }
}

// ─────────────────────────────────────────
// MARK: - PLATE
// ─────────────────────────────────────────

struct VehicleResolvePlateRequest: RequestProtocol {
    typealias EndpointType = VehicleResolvePlateEndpoint
    let plate: String
    let countryCode: String
    func toEndpoint() -> VehicleResolvePlateEndpoint { VehicleResolvePlateEndpoint(plate: plate, countryCode: countryCode) }
}

struct VehicleResolvePlateEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<VehicleResolveDataDTO>
    let plate: String
    let countryCode: String
    var path: String { kVehicleResolvePath }
    var method: HTTPMethod { .post }
    var payload: Encodable? { PlateBody(resolveType: "PLATE", plate: plate, countryCode: countryCode) }
}

private struct PlateBody: Encodable {
    let resolveType: String
    let plate: String
    let countryCode: String
    private enum CodingKeys: String, CodingKey {
        case resolveType = "resolve_type"
        case plate
        case countryCode = "country_code"
    }
}

// PERSON / COMPANY / MANUAL resolve types exist in the backend contract but
// have no UI entry point in this app — their endpoints were removed together
// with the manual wizard flow.
