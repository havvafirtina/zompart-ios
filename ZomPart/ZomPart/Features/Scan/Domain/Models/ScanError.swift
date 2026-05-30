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
        /// Backend AI providers (Gemini + OpenAI fallback) all failed.
        /// Usually a transient capacity spike — retrying in a few seconds works.
        case aiTemporarilyUnavailable
        case unknown

        var localizedMessage: String {
                switch self {
                case .network:
                        return Localized.Error.network.localized
                case .tokenExpired:
                        return Localized.Error.tokenExpired.localized
                case .rateLimitExceeded:
                        return Localized.Error.rateLimitExceeded.localized
                case .scanNotFound:
                        return Localized.Error.scanNotFound.localized
                case .vehicleNotFound:
                        return Localized.Error.vehicleNotFound.localized
                case .invalidState:
                        return Localized.Error.invalidState.localized
                case .conflict:
                        return Localized.Error.conflict.localized
                case .noPhotosUploaded:
                        return Localized.Error.noPhotosUploaded.localized
                case .photoLimitReached:
                        return Localized.Error.photoLimitReached.localized
                case .aiTemporarilyUnavailable:
                        // TODO i18n: add `error.aiTemporarilyUnavailable` key to Localizable.xcstrings.
                        // Suggested copy: "AI is busy right now. Please try again in a few seconds."
                        return "AI is busy right now. Please try again in a few seconds."
                default:
                        return Localized.Error.unknown.localized
                }
        }
}
