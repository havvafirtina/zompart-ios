//
//  AuthSessionDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Domain model representing a successful authentication session.
/// Returned by `verifyOTP` and `refreshToken`.
struct AuthSessionDomain: Equatable, Sendable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
}
