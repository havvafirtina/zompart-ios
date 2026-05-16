//
//  AuthRefreshEndpoint.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - RequestProtocol

struct AuthRefreshRequest: RequestProtocol {
    typealias EndpointType = AuthRefreshEndpoint

    let refreshToken: String

    func toEndpoint() -> AuthRefreshEndpoint {
        AuthRefreshEndpoint(refreshToken: refreshToken)
    }
}

// MARK: - Endpoint

/// Transport-level endpoint for POST `/functions/v1/auth-refresh`.
/// Does not require a valid Bearer token — uses the refresh token in the body.
struct AuthRefreshEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<AuthRefreshDataDTO>

    let refreshToken: String

    var path: String { "/functions/v1/auth-refresh" }
    var method: HTTPMethod { .post }

    var payload: Encodable? {
        AuthRefreshRequestBody(refreshToken: refreshToken)
    }
}

// MARK: - Request Body

private struct AuthRefreshRequestBody: Encodable {
    let refreshToken: String

    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}
