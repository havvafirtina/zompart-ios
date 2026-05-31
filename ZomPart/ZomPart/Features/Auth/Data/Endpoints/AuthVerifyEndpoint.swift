//
//  AuthVerifyEndpoint.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - RequestProtocol

struct AuthVerifyRequest: RequestProtocol {
    typealias EndpointType = AuthVerifyEndpoint

    let email: String
    let token: String

    func toEndpoint() -> AuthVerifyEndpoint {
        AuthVerifyEndpoint(email: email, token: token)
    }
}

// MARK: - Endpoint

/// Transport-level endpoint for POST `/functions/v1/auth-verify`.
struct AuthVerifyEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<AuthSessionDataDTO>

    let email: String
    let token: String

    var path: String { "/functions/v1/auth-verify" }
    var method: HTTPMethod { .post }

    var payload: Encodable? {
        AuthVerifyRequestBody(email: email, token: token, type: "email")
    }
}

// MARK: - Request Body

private struct AuthVerifyRequestBody: Encodable {
    let email: String
    let token: String
    let type: String
}
