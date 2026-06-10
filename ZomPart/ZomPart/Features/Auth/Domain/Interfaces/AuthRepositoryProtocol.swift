//
//  AuthRepositoryProtocol.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Domain interface for authentication operations.
/// Implemented by `AuthRepository` in the Data layer.
protocol AuthRepositoryProtocol: Sendable {
    func sendOTP(
        email: String,
        intent: AuthOTPIntent,
        firstName: String?,
        lastName: String?
    ) async throws -> AuthOTPResultDomain

    func verifyOTP(email: String, token: String) async throws -> AuthSessionDomain

    func logout(scope: AuthLogoutScope) async throws

    func requestAccountDeletion() async throws -> AuthDeleteRequestDomain

    func confirmAccountDeletion(email: String, token: String) async throws
}
