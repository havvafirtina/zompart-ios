//
//  AuthRepository.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Concrete repository that talks to the Supabase auth edge functions via `HTTPClient`.
/// Uses `actor` isolation to satisfy `Sendable`.
actor AuthRepository: AuthRepositoryProtocol {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: - OTP

    func sendOTP(
        email: String,
        intent: AuthOTPIntent,
        firstName: String?,
        lastName: String?
    ) async throws -> AuthOTPResultDomain {
        do {
            let request = AuthOTPRequest(email: email, intent: intent, firstName: firstName, lastName: lastName)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw AuthError.emptyResponse }
            return envelope.toModel()
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch let error as AuthError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapOTPError(httpError)
        } catch {
            throw AuthError.unknown
        }
    }

    // MARK: - Verify

    func verifyOTP(email: String, token: String) async throws -> AuthSessionDomain {
        do {
            let request = AuthVerifyRequest(email: email, token: token)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw AuthError.emptyResponse }
            return envelope.toModel()
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch let error as AuthError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapVerifyError(httpError)
        } catch {
            throw AuthError.unknown
        }
    }

    // MARK: - Logout

    func logout(scope: AuthLogoutScope) async throws {
        do {
            let request = AuthLogoutRequest(scope: scope)
            _ = try await client.submitRequest(request: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch let error as AuthError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapTokenError(httpError)
        } catch {
            throw AuthError.unknown
        }
    }

    // MARK: - Account Deletion

    func requestAccountDeletion() async throws -> AuthDeleteRequestDomain {
        do {
            let request = AuthDeleteRequestRequest()
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw AuthError.emptyResponse }
            return envelope.toModel()
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch let error as AuthError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapTokenError(httpError)
        } catch {
            throw AuthError.unknown
        }
    }

    func confirmAccountDeletion(email: String, token: String) async throws {
        do {
            let request = AuthDeleteConfirmRequest(email: email, token: token)
            _ = try await client.submitRequest(request: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch let error as AuthError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapDeleteConfirmError(httpError)
        } catch {
            throw AuthError.unknown
        }
    }

    // MARK: - Error Mapping

    private static func mapOTPError(_ error: HTTPClientError) -> AuthError {
        switch error {
        case .clientError(statusCode: 409, _): return .emailAlreadyRegistered
        case .notFound: return .emailNotRegistered
        case .clientError(statusCode: 429, let data):
            return .rateLimitExceeded(retryAfter: APIErrorParser.retryAfterSeconds(from: data))
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidIntent, .missingFields, .signupMetadataRequired: return .validationFailed
            default: return .validationFailed
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapVerifyError(_ error: HTTPClientError) -> AuthError {
        switch error {
        case .clientError(statusCode: 429, let data):
            return .rateLimitExceeded(retryAfter: APIErrorParser.retryAfterSeconds(from: data))
        case .clientError: return .otpInvalid
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapTokenError(_ error: HTTPClientError) -> AuthError {
        switch error {
        case .unauthorized: return .tokenExpired
        case .clientError(statusCode: 429, let data):
            return .rateLimitExceeded(retryAfter: APIErrorParser.retryAfterSeconds(from: data))
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapDeleteConfirmError(_ error: HTTPClientError) -> AuthError {
        switch error {
        case .clientError(statusCode: 410, _): return .deletionRequestExpired
        case .serverError(statusCode: 500, _): return .deletionFailed
        case .clientError(statusCode: 429, let data):
            return .rateLimitExceeded(retryAfter: APIErrorParser.retryAfterSeconds(from: data))
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .requestExpired: return .deletionRequestExpired
            case .noPendingRequest: return .noPendingDeletionRequest
            default: return .noPendingDeletionRequest
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
