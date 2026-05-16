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

// MARK: - Completed step DTO (MANUAL flow)

struct VehicleCompletedStepDTO: Decodable, Sendable {
    let step: String
    let value: String
    let isOptional: Bool?

    private enum CodingKeys: String, CodingKey {
        case step, value
        case isOptional = "is_optional"
    }

    func toModel() -> VehicleManualCompletedStepDomain {
        VehicleManualCompletedStepDomain(
            step: VehicleManualStepDomain(rawValue: step) ?? .year,
            value: value,
            isOptional: isOptional ?? false
        )
    }
}

// MARK: - Resolution DTO

struct VehicleResolutionDTO: Decodable, Sendable {
    let resolveType: String
    let isResolved: Bool
    let isNew: Bool?
    let sessionId: String?
    let nextStep: String?
    let nextStepIsOptional: Bool?
    let options: [String]?
    let completedSteps: [VehicleCompletedStepDTO]?

    private enum CodingKeys: String, CodingKey {
        case isResolved        = "is_resolved"
        case isNew             = "is_new"
        case sessionId         = "session_id"
        case nextStep          = "next_step"
        case nextStepIsOptional = "next_step_is_optional"
        case completedSteps    = "completed_steps"
        case resolveType       = "resolve_type"
        case options
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
            resolution: resolution
        )
    }
}

// MARK: - Intermediate domain type used only inside the Data layer

/// Carries the raw parsed response before the repository extracts the specific return value.
struct VehicleResponseDomain: Sendable {
    let vehicles: [VehicleDomain]
    let resolution: VehicleResolutionDTO?
}
