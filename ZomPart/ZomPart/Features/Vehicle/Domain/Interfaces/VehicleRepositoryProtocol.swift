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
    func resolveByPersonNumber(_ personNumber: String, countryCode: String) async throws -> VehicleResolveResultDomain
    func resolveByOrganizationNumber(_ orgNumber: String, countryCode: String) async throws -> VehicleResolveResultDomain

    // MARK: - Manual flow

    /// Returns the current pending MANUAL session, or nil if none exists.
    func fetchManualSession() async throws -> VehicleManualSessionDomain?

    /// Submits one step of the MANUAL flow.
    /// Returns `.resolved` when all steps are done, `.inProgress` otherwise.
    func submitManualStep(
        _ value: VehicleManualStepValueDomain,
        sessionId: String?,
        countryCode: String
    ) async throws -> VehicleManualResultDomain
}
