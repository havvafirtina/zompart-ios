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
        case rateLimitExceeded
        case network
        case emptyResponse
        case unknown
}
