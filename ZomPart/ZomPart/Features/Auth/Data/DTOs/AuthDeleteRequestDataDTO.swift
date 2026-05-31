//
//  AuthDeleteRequestDataDTO.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// DTO for the `data` field inside the auth-delete-request success envelope.
struct AuthDeleteRequestDataDTO: ResponseProtocol {
    typealias ModelType = AuthDeleteRequestDomain

    let expiresInMinutes: Int

    private enum CodingKeys: String, CodingKey {
        case expiresInMinutes = "expires_in_minutes"
    }

    func toModel() -> AuthDeleteRequestDomain {
        AuthDeleteRequestDomain(expiresInMinutes: expiresInMinutes)
    }
}
