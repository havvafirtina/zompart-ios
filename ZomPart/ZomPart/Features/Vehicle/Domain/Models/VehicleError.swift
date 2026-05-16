//
//  VehicleError.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Feature-specific error type for the Vehicle module.
/// `HTTPClientError` is never exposed beyond the repository layer.
enum VehicleError: Error, Equatable {
    case invalidVIN
    case invalidPlate
    case invalidCountryCode
    case invalidStep
    case invalidSession
    case vehicleNotFound
    case rateLimitExceeded
    case providerUnavailable
    case network
    case emptyResponse
    case unknown
}
