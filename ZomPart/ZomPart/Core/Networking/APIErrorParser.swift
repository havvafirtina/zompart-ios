//
//  APIErrorParser.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

enum APIErrorCode: String {
        // Auth
        case missingFields = "MISSING_FIELDS"
        case invalidIntent = "INVALID_INTENT"
        case signupMetadataRequired = "SIGNUP_METADATA_REQUIRED"
        case emailAlreadyRegistered = "EMAIL_ALREADY_REGISTERED"
        case emailNotRegistered = "EMAIL_NOT_REGISTERED"
        case verifyFailed = "VERIFY_FAILED"
        case refreshFailed = "REFRESH_FAILED"
        case noPendingRequest = "NO_PENDING_REQUEST"
        case requestExpired = "REQUEST_EXPIRED"
        case deleteFailed = "DELETE_FAILED"

        // Vehicle
        case invalidVIN = "INVALID_VIN"
        case invalidPlate = "INVALID_PLATE"
        case invalidPersonNumber = "INVALID_PERSON_NUMBER"
        case invalidOrganizationNumber = "INVALID_ORGANIZATION_NUMBER"
        case invalidCountryCode = "INVALID_COUNTRY_CODE"
        case invalidStep = "INVALID_STEP"
        case invalidSession = "INVALID_SESSION"
        case providerUnavailable = "PROVIDER_UNAVAILABLE"

        // Scan
        case invalidUUID = "INVALID_UUID"
        case invalidScanType = "INVALID_SCAN_TYPE"
        case invalidMimeType = "INVALID_MIME_TYPE"
        case photoLimitReached = "PHOTO_LIMIT_REACHED"
        case noPhotosUploaded = "NO_PHOTOS_UPLOADED"
        case invalidState = "INVALID_STATE"
        case invalidPart = "INVALID_PART"
        case invalidAction = "INVALID_ACTION"
        case conflict = "CONFLICT"

        // Shared
        case vehicleNotFound = "VEHICLE_NOT_FOUND"
        case scanNotFound = "SCAN_NOT_FOUND"
        case offerNotFound = "OFFER_NOT_FOUND"
        case rateLimitExceeded = "RATE_LIMIT_EXCEEDED"
        case unauthorized = "UNAUTHORIZED"
        case missingApikey = "MISSING_APIKEY"
}

enum APIErrorParser {
        private struct ErrorEnvelope: Decodable {
                let error: ErrorBody?
                struct ErrorBody: Decodable {
                        let code: String
                }
        }

        static func code(from data: Data) -> APIErrorCode? {
                guard let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) else {
                        return nil
                }
                return envelope.error.flatMap { APIErrorCode(rawValue: $0.code) }
        }
}
