//
//  ScanRepository.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Concrete repository that talks to the Supabase scan edge functions via `HTTPClient`.
/// Uses `actor` isolation to satisfy `Sendable`.
actor ScanRepository: ScanRepositoryProtocol {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: - Start

    func startScan(
        vehicleId: String,
        inputType: ScanInputTypeDomain,
        inputText: String?,
        startOver: Bool
    ) async throws -> ScanDomain {
        do {
            let request = ScanStartRequest(
                vehicleId: vehicleId,
                inputType: inputType,
                inputText: inputText,
                startOver: startOver
            )
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapStartError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Upload URLs

    func getUploadURLs(scanId: String, contentTypes: [String]) async throws -> [ScanUploadUrlItemDomain] {
        do {
            let request = ScanUploadUrlRequest(scanId: scanId, contentTypes: contentTypes)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapUploadError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Process

    func processScan(scanId: String) async throws -> ScanProcessResultDomain {
        do {
            let request = ScanProcessRequest(scanId: scanId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapProcessError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Feedback

    func selectPart(scanId: String, partCandidateId: String) async throws -> ScanFeedbackResultDomain {
        do {
            let request = ScanSelectPartRequest(scanId: scanId, partCandidateId: partCandidateId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapFeedbackError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Delete

    func deleteScan(scanId: String) async throws {
        do {
            let request = ScanDeleteRequest(scanId: scanId)
            _ = try await client.submitRequest(request: request)
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapCommonError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Error mapping

    private static func mapStartError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .clientError(statusCode: 400): return .invalidUUID
        case .notFound: return .vehicleNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapUploadError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .clientError(statusCode: 400): return .invalidScanType
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapProcessError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .clientError(statusCode: 400): return .invalidState
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 409): return .conflict
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapFeedbackError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .clientError(statusCode: 400): return .invalidState
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapCommonError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .clientError(statusCode: 400): return .invalidUUID
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
