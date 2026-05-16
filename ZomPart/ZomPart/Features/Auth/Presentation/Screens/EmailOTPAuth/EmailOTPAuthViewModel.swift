//
//  EmailOTPAuthViewModel.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import Observation

@MainActor
@Observable
final class EmailOTPAuthViewModel {

    enum ViewState: Equatable {
        case idle
        case loading
        case success
        case error(message: String)
    }

    private(set) var state: ViewState = .idle

    private let authRepository: AuthRepositoryProtocol
    private let onOTPSent: (String) -> Void

    init(
        authRepository: AuthRepositoryProtocol,
        onOTPSent: @escaping (String) -> Void
    ) {
        self.authRepository = authRepository
        self.onOTPSent = onOTPSent
    }

    func sendOTP(
        email: String,
        intent: AuthOTPIntent,
        firstName: String?,
        lastName: String?
    ) async {
        state = .loading
        do {
            _ = try await authRepository.sendOTP(
                email: email,
                intent: intent,
                firstName: firstName,
                lastName: lastName
            )
            state = .success
            onOTPSent(email)
        } catch let error as AuthError {
            state = .error(message: Self.message(for: error))
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    private static func message(for error: AuthError) -> String {
        switch error {
        case .validationFailed:
            return "Please check the entered information and try again."
        case .emailAlreadyRegistered:
            return "This email is already registered. Please log in instead."
        case .network:
            return "No internet connection. Please try again later."
        case .emptyResponse:
            return "An unexpected error occurred. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
