//
//  HistoryRepository.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Concrete repository that talks to the Supabase scan-get edge function via `HTTPClient`.
/// Uses `actor` isolation to satisfy `Sendable`.
actor HistoryRepository: HistoryRepositoryProtocol {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: - Single scan

    func fetchScan(scanId: String) async throws -> ScanDetailDomain {
        do {
            let request = ScanGetSingleRequest(scanId: scanId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw HistoryError.emptyResponse }
            return envelope.toModel()
        } catch let e as HistoryError { throw e
        } catch let e as HTTPClientError { throw Self.mapSingleError(e)
        } catch { throw HistoryError.unknown }
    }

    // MARK: - History list

    func fetchHistory(vehicleId: String?, limit: Int, offset: Int) async throws -> HistoryPageDomain {
        do {
            let request = ScanGetHistoryRequest(vehicleId: vehicleId, limit: limit, offset: offset)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw HistoryError.emptyResponse }
            return envelope.toModel()
        } catch let e as HistoryError { throw e
        } catch let e as HTTPClientError { throw Self.mapHistoryError(e)
        } catch { throw HistoryError.unknown }
    }

    // MARK: - Error mapping

    private static func mapSingleError(_ e: HTTPClientError) -> HistoryError {
        switch e {
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidUUID: return .invalidUUID
            default: return .invalidUUID
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapHistoryError(_ e: HTTPClientError) -> HistoryError {
        switch e {
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidUUID: return .invalidUUID
            default: return .invalidPagination
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
