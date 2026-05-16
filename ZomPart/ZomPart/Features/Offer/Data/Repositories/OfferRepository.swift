//
//  OfferRepository.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Concrete repository that talks to the Supabase offer edge functions via `HTTPClient`.
/// Uses `actor` isolation to satisfy `Sendable`.
actor OfferRepository: OfferRepositoryProtocol {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: - List offers

    func listOffers(scanId: String, sort: OfferSortDomain) async throws -> OfferListDomain {
        do {
            let request = ScanOffersRequest(scanId: scanId, sort: sort)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw OfferError.emptyResponse }
            return envelope.toModel()
        } catch let e as OfferError { throw e
        } catch let e as HTTPClientError { throw Self.mapListError(e)
        } catch { throw OfferError.unknown }
    }

    // MARK: - Record click

    func recordClick(offerId: String, scanId: String) async throws -> OfferClickResultDomain {
        do {
            let request = OffersClickRequest(offerId: offerId, scanId: scanId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw OfferError.emptyResponse }
            return envelope.toModel()
        } catch let e as OfferError { throw e
        } catch let e as HTTPClientError { throw Self.mapClickError(e)
        } catch { throw OfferError.unknown }
    }

    // MARK: - Error mapping

    private static func mapListError(_ e: HTTPClientError) -> OfferError {
        switch e {
        case .clientError(statusCode: 400): return .invalidUUID
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapClickError(_ e: HTTPClientError) -> OfferError {
        switch e {
        case .clientError(statusCode: 400): return .invalidUUID
        case .notFound: return .offerNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
