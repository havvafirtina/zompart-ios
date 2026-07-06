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
    case vehicleNotFound
    case tokenExpired
    /// `retryAfter` = seconds until the window resets (backend `meta.retry_after`).
    case rateLimitExceeded(retryAfter: Int?)
    case providerUnavailable
    case network
    case emptyResponse
    case unknown
}
