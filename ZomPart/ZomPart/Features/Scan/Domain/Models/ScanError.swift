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
    /// A signed-URL PUT returned a non-2xx response (URLs expire after 60s)
    /// or a malformed upload URL was received.
    case photoUploadFailed
    case noPhotosUploaded
    case invalidState
    case invalidPart
    case invalidAction
    case conflict
    case tokenExpired
    /// `retryAfter` = seconds until the window resets (backend `meta.retry_after`).
    case rateLimitExceeded(retryAfter: Int?)
    case network
    case emptyResponse
    /// Backend AI providers (Gemini + OpenAI fallback) all failed.
    /// Usually a transient capacity spike — retrying in a few seconds works.
    case aiTemporarilyUnavailable
    /// MANUAL_SEARCH could not resolve the typed part number
    /// (404 PART_LOOKUP_FAILED); the scan keeps its previous state.
    case partLookupFailed
    case unknown
}
