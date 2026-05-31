//
//  AuthDeleteEndpoints.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - Delete Request

struct AuthDeleteRequestRequest: RequestProtocol {
    typealias EndpointType = AuthDeleteRequestEndpoint

    func toEndpoint() -> AuthDeleteRequestEndpoint { AuthDeleteRequestEndpoint() }
}

/// Transport-level endpoint for POST `/functions/v1/auth-delete-request`. Requires Bearer token.
struct AuthDeleteRequestEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<AuthDeleteRequestDataDTO>

    var path: String { "/functions/v1/auth-delete-request" }
    var method: HTTPMethod { .post }
    var payload: Encodable? { nil }
}

// MARK: - Delete Confirm

struct AuthDeleteConfirmRequest: RequestProtocol {
    typealias EndpointType = AuthDeleteConfirmEndpoint

    let email: String
    let token: String

    func toEndpoint() -> AuthDeleteConfirmEndpoint {
        AuthDeleteConfirmEndpoint(email: email, token: token)
    }
}

/// Transport-level endpoint for POST `/functions/v1/auth-delete-confirm`.
struct AuthDeleteConfirmEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<AuthDeleteConfirmDataDTO>

    let email: String
    let token: String

    var path: String { "/functions/v1/auth-delete-confirm" }
    var method: HTTPMethod { .post }

    var payload: Encodable? {
        AuthDeleteConfirmRequestBody(email: email, token: token)
    }
}

// MARK: - Request Body

private struct AuthDeleteConfirmRequestBody: Encodable {
    let email: String
    let token: String
    let type: String = "email"
}
