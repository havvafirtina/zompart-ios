//
//  AuthLogoutEndpoint.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - RequestProtocol

struct AuthLogoutRequest: RequestProtocol {
    typealias EndpointType = AuthLogoutEndpoint

    let scope: AuthLogoutScope

    func toEndpoint() -> AuthLogoutEndpoint {
        AuthLogoutEndpoint(scope: scope)
    }
}

// MARK: - Endpoint

/// Transport-level endpoint for POST `/functions/v1/auth-logout`. Requires Bearer token.
struct AuthLogoutEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<AuthLogoutDataDTO>

    let scope: AuthLogoutScope

    var path: String { "/functions/v1/auth-logout" }
    var method: HTTPMethod { .post }

    var payload: Encodable? {
        AuthLogoutRequestBody(scope: scope)
    }
}

// MARK: - Request Body

private struct AuthLogoutRequestBody: Encodable {
    let scope: AuthLogoutScope
}
