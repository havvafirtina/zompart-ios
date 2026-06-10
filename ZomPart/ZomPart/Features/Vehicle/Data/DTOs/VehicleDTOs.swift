//
//  VehicleDTOs.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - Vehicle record DTO

struct VehicleDTO: Decodable, Sendable {
    let id: String
    let make: String
    let model: String
    let year: Int?
    let engineCode: String?
    let trim: String?
    let resolveMethod: String
    let countryCode: String
    let vin: String?
    let plate: String?

    private enum CodingKeys: String, CodingKey {
        case id, make, model, year, trim, vin, plate
        case engineCode    = "engine_code"
        case resolveMethod = "resolve_method"
        case countryCode   = "country_code"
    }

    func toModel() -> VehicleDomain {
        VehicleDomain(
            id: id,
            make: make,
            model: model,
            year: year,
            engineCode: engineCode,
            trim: trim,
            resolveMethod: VehicleResolveMethodDomain(rawValue: resolveMethod) ?? .manual,
            countryCode: countryCode,
            vin: vin,
            plate: plate
        )
    }
}

// MARK: - Resolution DTO

struct VehicleResolutionDTO: Decodable, Sendable {
    let resolveType: String
    let isResolved: Bool
    let isNew: Bool?

    private enum CodingKeys: String, CodingKey {
        case isResolved  = "is_resolved"
        case isNew       = "is_new"
        case resolveType = "resolve_type"
    }

    func toModel() -> VehicleResolutionDomain {
        VehicleResolutionDomain(
            resolveType: resolveType,
            isResolved: isResolved,
            isNew: isNew
        )
    }
}

// MARK: - Top-level data envelope DTO

/// DTO for the `data` field inside all vehicle-resolve success envelopes.
/// Shape: `{ "vehicles": [...], "resolution": {...} | null }`.
struct VehicleResolveDataDTO: ResponseProtocol {
    typealias ModelType = VehicleResponseDomain

    let vehicles: [VehicleDTO]
    let resolution: VehicleResolutionDTO?

    func toModel() -> VehicleResponseDomain {
        VehicleResponseDomain(
            vehicles: vehicles.map { $0.toModel() },
            resolution: resolution?.toModel()
        )
    }
}

// MARK: - Intermediate domain type used only inside the Data layer

/// Carries the raw parsed response before the repository extracts the specific return value.
struct VehicleResponseDomain: Sendable {
    let vehicles: [VehicleDomain]
    let resolution: VehicleResolutionDomain?
}
