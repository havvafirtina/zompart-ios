//
//  AuthOTPDataDTO.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// DTO for the `data` field inside the auth-otp success envelope: `{ "id": "ok" }`.
struct AuthOTPDataDTO: ResponseProtocol {
    typealias ModelType = AuthOTPResultDomain

    let id: String

    func toModel() -> AuthOTPResultDomain {
        AuthOTPResultDomain(id: id)
    }
}
