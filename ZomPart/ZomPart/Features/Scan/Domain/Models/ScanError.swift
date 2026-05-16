//
//  ScanError.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Feature-specific error type for the Scan module.
/// `HTTPClientError` is never exposed beyond the repository layer.
enum ScanError: Error, Equatable {
    case invalidUUID
    case vehicleNotFound
    case scanNotFound
    case invalidScanType
    case invalidMimeType
    case photoLimitReached
    case noPhotosUploaded
    case invalidState
    case invalidPart
    case invalidAction
    case conflict
    case tokenExpired
    case rateLimitExceeded
    case network
    case emptyResponse
    case unknown
}
