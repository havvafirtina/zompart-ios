//
//  AuthError.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Feature-specific error type for the Auth module.
/// `HTTPClientError` is never exposed beyond the repository layer.
enum AuthError: Error, Equatable {
    case validationFailed
    case emailAlreadyRegistered
    case emailNotRegistered
    case otpInvalid
    case tokenExpired
    /// `retryAfter` = seconds until the window resets (backend `meta.retry_after`).
    case rateLimitExceeded(retryAfter: Int?)
    case noPendingDeletionRequest
    case deletionRequestExpired
    case deletionFailed
    case network
    case emptyResponse
    case unknown
}
