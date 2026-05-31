//
//  AuthOTPEndpoint.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - RequestProtocol

/// Feature-level request model for sending an OTP email.
/// Converts itself into `AuthOTPEndpoint` via `toEndpoint()`.
struct AuthOTPRequest: RequestProtocol {
    typealias EndpointType = AuthOTPEndpoint

    let email: String
    let intent: AuthOTPIntent
    let firstName: String?
    let lastName: String?

    func toEndpoint() -> AuthOTPEndpoint {
        AuthOTPEndpoint(
            email: email,
            intent: intent,
            firstName: firstName,
            lastName: lastName
        )
    }
}

// MARK: - Endpoint

/// Transport-level endpoint for POST `/functions/v1/auth-otp`.
struct AuthOTPEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<AuthOTPDataDTO>

    let email: String
    let intent: AuthOTPIntent
    let firstName: String?
    let lastName: String?

    var path: String { "/functions/v1/auth-otp" }
    var method: HTTPMethod { .post }

    var payload: Encodable? {
        AuthOTPRequestBody(
            email: email,
            intent: intent,
            firstName: firstName,
            lastName: lastName
        )
    }
}

// MARK: - Request Body

/// Private encodable matching the exact JSON keys expected by the Supabase edge function.
private struct AuthOTPRequestBody: Encodable {
    let email: String
    let intent: AuthOTPIntent
    let firstName: String?
    let lastName: String?

    private enum CodingKeys: String, CodingKey {
        case email
        case intent
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
