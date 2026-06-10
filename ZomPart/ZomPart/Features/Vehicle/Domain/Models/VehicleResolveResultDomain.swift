//
//  VehicleResolveResultDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Result of a successful VIN / PLATE resolution.
struct VehicleResolveResultDomain: Equatable, Sendable {
    let vehicle: VehicleDomain
    /// True when the vehicle was newly added to the garage; false when it was a duplicate.
    let isNew: Bool
}

/// Domain representation of the resolution metadata returned by vehicle-resolve.
/// The wire object also carries multi-step session fields (session_id,
/// next_step, completed_steps) used by resolve types this app does not
/// initiate — they are intentionally not decoded.
struct VehicleResolutionDomain: Equatable, Sendable {
    let resolveType: String
    let isResolved: Bool
    let isNew: Bool?
}
