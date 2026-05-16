//
//  OTPVerifyViewModel.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import Observation

@MainActor
@Observable
final class OTPVerifyViewModel {

    enum ViewState: Equatable {
        case idle
        case loading
        case success
        case error(message: String)
    }

    private(set) var state: ViewState = .idle
    var otpCode = ""

    let email: String

    private let authRepository: AuthRepositoryProtocol
    private let onVerified: (AuthSessionDomain) -> Void

    init(
        email: String,
        authRepository: AuthRepositoryProtocol,
        onVerified: @escaping (AuthSessionDomain) -> Void
    ) {
        self.email = email
        self.authRepository = authRepository
        self.onVerified = onVerified
    }

    func verify() async {
        guard !otpCode.isEmpty else { return }
        state = .loading
        do {
            let session = try await authRepository.verifyOTP(email: email, token: otpCode)
            state = .success
            onVerified(session)
        } catch let error as AuthError {
            state = .error(message: Self.message(for: error))
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    private static func message(for error: AuthError) -> String {
        switch error {
        case .otpInvalid:
            return "Invalid or expired code. Please try again."
        case .tokenExpired:
            return "Session expired. Please start over."
        case .network:
            return "No internet connection. Please try again later."
        case .emptyResponse:
            return "An unexpected error occurred. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
