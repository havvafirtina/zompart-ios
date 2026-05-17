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

// ─────────────────────────────────────────
// MARK: - PERSON
// ─────────────────────────────────────────

struct VehicleResolvePersonRequest: RequestProtocol {
        typealias EndpointType = VehicleResolvePersonEndpoint
        let personNumber: String
        let countryCode: String
        func toEndpoint() -> VehicleResolvePersonEndpoint { VehicleResolvePersonEndpoint(personNumber: personNumber, countryCode: countryCode) }
}

struct VehicleResolvePersonEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<VehicleResolveDataDTO>
        let personNumber: String
        let countryCode: String
        var path: String { kVehicleResolvePath }
        var method: HTTPMethod { .post }
        var payload: Encodable? { PersonBody(resolveType: "PERSON", personNumber: personNumber, countryCode: countryCode) }
}

private struct PersonBody: Encodable {
        let resolveType: String
        let personNumber: String
        let countryCode: String
        private enum CodingKeys: String, CodingKey {
                case resolveType   = "resolve_type"
                case personNumber  = "person_number"
                case countryCode   = "country_code"
        }
}

// ─────────────────────────────────────────
// MARK: - COMPANY
// ─────────────────────────────────────────

struct VehicleResolveCompanyRequest: RequestProtocol {
        typealias EndpointType = VehicleResolveCompanyEndpoint
        let organizationNumber: String
        let countryCode: String
        func toEndpoint() -> VehicleResolveCompanyEndpoint { VehicleResolveCompanyEndpoint(organizationNumber: organizationNumber, countryCode: countryCode) }
}

struct VehicleResolveCompanyEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<VehicleResolveDataDTO>
        let organizationNumber: String
        let countryCode: String
        var path: String { kVehicleResolvePath }
        var method: HTTPMethod { .post }
        var payload: Encodable? { CompanyBody(resolveType: "COMPANY", organizationNumber: organizationNumber, countryCode: countryCode) }
}

private struct CompanyBody: Encodable {
        let resolveType: String
        let organizationNumber: String
        let countryCode: String
        private enum CodingKeys: String, CodingKey {
                case resolveType         = "resolve_type"
                case organizationNumber  = "organization_number"
                case countryCode         = "country_code"
        }
}

// ─────────────────────────────────────────
// MARK: - MANUAL — Pending lookup
// ─────────────────────────────────────────

struct VehicleManualLookupRequest: RequestProtocol {
        typealias EndpointType = VehicleManualLookupEndpoint
        func toEndpoint() -> VehicleManualLookupEndpoint { VehicleManualLookupEndpoint() }
}

/// POST `{ resolve_type: "MANUAL" }` — returns the pending session if one exists.
struct VehicleManualLookupEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<VehicleResolveDataDTO>
        var path: String { kVehicleResolvePath }
        var method: HTTPMethod { .post }
        var payload: Encodable? { ManualLookupBody() }
}

private struct ManualLookupBody: Encodable {
        let resolveType = "MANUAL"
        private enum CodingKeys: String, CodingKey { case resolveType = "resolve_type" }
}

// ─────────────────────────────────────────
// MARK: - MANUAL — Step submission
// ─────────────────────────────────────────

/// `VehicleManualStepValueDomain` carries associated values and cannot conform to
/// `Encodable` automatically, so no `RequestProtocol` wrapper is provided.
/// The repository calls `client.submitRequest(endpoint:)` directly.
struct VehicleManualStepEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<VehicleResolveDataDTO>
        let value: VehicleManualStepValueDomain
        let sessionId: String?
        let countryCode: String
        var path: String { kVehicleResolvePath }
        var method: HTTPMethod { .post }
        var payload: Encodable? { ManualStepBody(value: value, sessionId: sessionId, countryCode: countryCode) }
}

private struct ManualStepBody: Encodable {
        let resolveType  = "MANUAL"
        let sessionId: String?
        let currentStep: String
        let countryCode: String
        let year: Int?
        let make: String?
        let model: String?
        let trim: String?
        let engineCode: String?

        init(value: VehicleManualStepValueDomain, sessionId: String?, countryCode: String) {
                self.sessionId   = sessionId
                self.currentStep = value.step.rawValue
                self.countryCode = countryCode
                switch value {
                case .year(let y):    year = y;  make = nil; model = nil; trim = nil; engineCode = nil
                case .make(let m):    year = nil; make = m;  model = nil; trim = nil; engineCode = nil
                case .model(let m):   year = nil; make = nil; model = m;  trim = nil; engineCode = nil
                case .trim(let t):    year = nil; make = nil; model = nil; trim = t;   engineCode = nil
                case .engine(let e):  year = nil; make = nil; model = nil; trim = nil; engineCode = e
                }
        }

        private enum CodingKeys: String, CodingKey {
                case resolveType  = "resolve_type"
                case sessionId    = "session_id"
                case currentStep  = "current_step"
                case countryCode  = "country_code"
                case year, make, model, trim
                case engineCode   = "engine_code"
        }
}
