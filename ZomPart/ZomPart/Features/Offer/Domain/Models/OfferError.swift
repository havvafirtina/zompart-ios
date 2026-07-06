//
//  OfferError.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Feature-specific error type for the Offer module.
/// `HTTPClientError` is never exposed beyond the repository layer.
enum OfferError: Error, Equatable {
    case invalidUUID
    case scanNotFound
    case offerNotFound
    case tokenExpired
    /// `retryAfter` = seconds until the window resets (backend `meta.retry_after`).
    case rateLimitExceeded(retryAfter: Int?)
    /// Offer backend/provider is down (5xx) — transient, retry later.
    case serviceUnavailable
    case network
    case emptyResponse
    case unknown
}
