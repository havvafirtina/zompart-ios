//
//  AuthDeleteConfirmDataDTO.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// DTO for the `data` field inside the auth-delete-confirm success envelope.
struct AuthDeleteConfirmDataDTO: ResponseProtocol {
    typealias ModelType = Bool

    let deleted: Bool

    func toModel() -> Bool { deleted }
}
