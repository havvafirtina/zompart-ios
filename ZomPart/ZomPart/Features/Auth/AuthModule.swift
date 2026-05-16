//
//  AuthModule.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Static factory that wires Auth feature dependencies.
/// Called from the composition root; no state of its own.
enum AuthModule {

    static func makeAuthRepository(httpClient: HTTPClient) -> AuthRepositoryProtocol {
        AuthRepository(client: httpClient)
    }

    @MainActor
    static func makeEmailOTPAuthViewModel(
        httpClient: HTTPClient,
        onOTPSent: @escaping (String) -> Void
    ) -> EmailOTPAuthViewModel {
        EmailOTPAuthViewModel(
            authRepository: makeAuthRepository(httpClient: httpClient),
            onOTPSent: onOTPSent
        )
    }

    @MainActor
    static func makeOTPVerifyViewModel(
        httpClient: HTTPClient,
        email: String,
        onVerified: @escaping (AuthSessionDomain) -> Void
    ) -> OTPVerifyViewModel {
        OTPVerifyViewModel(
            email: email,
            authRepository: makeAuthRepository(httpClient: httpClient),
            onVerified: onVerified
        )
    }
}
