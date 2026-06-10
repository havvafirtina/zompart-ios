//
//  VehicleRepositoryProtocol.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Domain interface for vehicle resolution and garage management.
/// Implemented by `VehicleRepository` in the Data layer.
protocol VehicleRepositoryProtocol: Sendable {

    // MARK: - Garage

    func listVehicles() async throws -> [VehicleDomain]

    // MARK: - Resolve

    func resolveByVIN(_ vin: String, countryCode: String) async throws -> VehicleResolveResultDomain
    func resolveByPlate(_ plate: String, countryCode: String) async throws -> VehicleResolveResultDomain
}
