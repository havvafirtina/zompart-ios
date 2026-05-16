//
//  AuthRefreshDataDTO.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// DTO for the `data` field inside the auth-refresh success envelope.
struct AuthRefreshDataDTO: ResponseProtocol {
    typealias ModelType = AuthSessionDomain

    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }

    func toModel() -> AuthSessionDomain {
        AuthSessionDomain(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}
