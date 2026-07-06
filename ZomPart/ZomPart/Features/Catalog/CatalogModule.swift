import Foundation
import SBNetworking

extension CatalogError {

    var localizedMessage: String {
        switch self {
        case .vehicleNotFound:
            return Localized.Error.vehicleNotFound.localized
        case .catalogUnavailable:
            return Localized.Catalog.errorNoCatalog.localized
        case .countryNotSupported:
            return Localized.Garage.errorInvalidCountry.localized
        case .tokenExpired:
            return Localized.Error.tokenExpired.localized
        case .rateLimitExceeded(let retryAfter):
            return retryAfter.map { Localized.Error.rateLimitRetryIn.localized($0) }
                ?? Localized.Error.rateLimitExceeded.localized
        case .network:
            return Localized.Error.network.localized
        default:
            return Localized.Error.unknown.localized
        }
    }
}

enum CatalogModule {

    static func makeCatalogRepository(httpClient: HTTPClient) -> CatalogRepositoryProtocol {
        CatalogRepository(client: httpClient)
    }

    @MainActor
    static func makeCatalogBrowseViewModel(env: AppEnvironment, vehicleId: String) -> CatalogBrowseViewModel {
        CatalogBrowseViewModel(
            vehicleId: vehicleId,
            catalogRepository: makeCatalogRepository(httpClient: env.httpClient)
        )
    }

    @MainActor
    static func makeCatalogArticlesViewModel(
        env: AppEnvironment,
        vehicleId: String,
        category: CatalogCategoryDomain
    ) -> CatalogArticlesViewModel {
        CatalogArticlesViewModel(
            vehicleId: vehicleId,
            category: category,
            catalogRepository: makeCatalogRepository(httpClient: env.httpClient)
        )
    }

    @MainActor
    static func makePartsSearchViewModel(env: AppEnvironment, vehicleId: String?) -> PartsSearchViewModel {
        PartsSearchViewModel(
            vehicleId: vehicleId,
            catalogRepository: makeCatalogRepository(httpClient: env.httpClient)
        )
    }
}
