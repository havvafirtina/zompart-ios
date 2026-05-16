//
//  AuthDeleteRequestDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Domain model returned when an account deletion request is initiated.
struct AuthDeleteRequestDomain: Equatable, Sendable {
    let expiresInMinutes: Int
}
