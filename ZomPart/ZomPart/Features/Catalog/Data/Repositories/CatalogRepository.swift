import Foundation
import SBNetworking

/// Concrete repository that talks to the Supabase catalog edge functions
/// (vehicle-parts, parts-search) via `HTTPClient`. Uses `actor` isolation to
/// satisfy `Sendable`.
actor CatalogRepository: CatalogRepositoryProtocol {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func categories(vehicleId: String) async throws -> CatalogCategoryPageDomain {
        do {
            let request = CatalogCategoriesRequest(vehicleId: vehicleId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw CatalogError.emptyResponse }
            return envelope.toModel()
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
        } catch let e as CatalogError { throw e
        } catch let e as HTTPClientError { throw Self.mapError(e)
        } catch { throw CatalogError.unknown }
    }

    func articles(vehicleId: String, categoryId: Int) async throws -> CatalogArticlesPageDomain {
        do {
            let request = CatalogArticlesRequest(vehicleId: vehicleId, categoryId: categoryId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw CatalogError.emptyResponse }
            return envelope.toModel()
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
        } catch let e as CatalogError { throw e
        } catch let e as HTTPClientError { throw Self.mapError(e)
        } catch { throw CatalogError.unknown }
    }

    func search(articleNumber: String, vehicleId: String?) async throws -> CatalogSearchPageDomain {
        do {
            let request = PartsSearchRequest(articleNumber: articleNumber, vehicleId: vehicleId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw CatalogError.emptyResponse }
            return envelope.toModel()
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
        } catch let e as CatalogError { throw e
        } catch let e as HTTPClientError { throw Self.mapError(e)
        } catch { throw CatalogError.unknown }
    }

    // MARK: - Error mapping

    private static func mapError(_ e: HTTPClientError) -> CatalogError {
        switch e {
        case .notFound: return .vehicleNotFound
        case .clientError(statusCode: 429, let data):
            return .rateLimitExceeded(retryAfter: APIErrorParser.retryAfterSeconds(from: data))
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .countryNotSupported: return .countryNotSupported
            // 400 CATALOG_LOOKUP_FAILED = vehicle has no carId / no usable data.
            case .catalogLookupFailed: return .catalogUnavailable
            default: return .unknown
            }
        // 502 TECDOC_LOOKUP_FAILED / 503 PROVIDER_UNAVAILABLE land here.
        case .serverError: return .catalogUnavailable
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
