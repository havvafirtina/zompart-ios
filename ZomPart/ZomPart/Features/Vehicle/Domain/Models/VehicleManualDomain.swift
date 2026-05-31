//
//  VehicleManualDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

// MARK: - Step name (for session state & display)

enum VehicleManualStepDomain: String, Equatable, Sendable {
    case year = "YEAR"
    case make = "MAKE"
    case model = "MODEL"
    case trim = "TRIM"
    case engine = "ENGINE"

    var isOptional: Bool { self == .trim || self == .engine }
}

// MARK: - Step value submitted by the user

/// Typed value submitted for each step in the MANUAL flow.
/// The enum case encodes both the step identity and the value.
enum VehicleManualStepValueDomain: Equatable, Sendable {
    case year(Int)
    case make(String)
    case model(String)
    case trim(String?)   // nil = skip (stored as null)
    case engine(String?) // nil = skip (stored as null)

    var step: VehicleManualStepDomain {
        switch self {
        case .year:   return .year
        case .make:   return .make
        case .model:  return .model
        case .trim:   return .trim
        case .engine: return .engine
        }
    }
}

// MARK: - Completed step record

struct VehicleManualCompletedStepDomain: Equatable, Sendable {
    let step: VehicleManualStepDomain
    let value: String
    let isOptional: Bool
}

// MARK: - In-progress session

struct VehicleManualSessionDomain: Equatable, Sendable {
    let sessionId: String
    let nextStep: VehicleManualStepDomain
    let nextStepIsOptional: Bool
    let options: [String]
    let completedSteps: [VehicleManualCompletedStepDomain]
}

// MARK: - Step submission result

enum VehicleManualResultDomain: Equatable, Sendable {
    /// All steps completed; vehicle has been created in the garage.
    case resolved(VehicleResolveResultDomain)
    /// More steps remain; continue with the returned session state.
    case inProgress(VehicleManualSessionDomain)
}
