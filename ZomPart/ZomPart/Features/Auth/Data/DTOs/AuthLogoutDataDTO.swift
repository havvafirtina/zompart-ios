//
//  AuthLogoutDataDTO.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// DTO for the `data` field inside the auth-logout success envelope.
struct AuthLogoutDataDTO: ResponseProtocol {
        typealias ModelType = Bool

        let loggedOut: Bool

        private enum CodingKeys: String, CodingKey {
                case loggedOut = "logged_out"
        }

        func toModel() -> Bool { loggedOut }
}
