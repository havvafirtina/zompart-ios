//
//  VehicleResolveResultDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Result of a successful VIN / PLATE / PERSON / COMPANY resolution.
struct VehicleResolveResultDomain: Equatable, Sendable {
    let vehicle: VehicleDomain
    /// True when the vehicle was newly added to the garage; false when it was a duplicate.
    let isNew: Bool
}
