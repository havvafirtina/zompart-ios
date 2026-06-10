import Foundation
import SBNetworking

extension OfferError {

    var localizedMessage: String {
        switch self {
        case .scanNotFound:
            return Localized.Error.scanNotFound.localized
        case .offerNotFound:
            return Localized.Offers.errorOfferNotFound.localized
        case .tokenExpired:
            return Localized.Error.tokenExpired.localized
        case .rateLimitExceeded:
            return Localized.Error.rateLimitExceeded.localized
        case .network:
            return Localized.Error.network.localized
        default:
            return Localized.Error.unknown.localized
        }
    }
}

enum OfferModule {

    static func makeOfferRepository(httpClient: HTTPClient) -> OfferRepositoryProtocol {
        OfferRepository(client: httpClient)
    }

    @MainActor
    static func makeOffersListViewModel(
        env: AppEnvironment,
        scanId: String
    ) -> OffersListViewModel {
        OffersListViewModel(
            scanId: scanId,
            offerRepository: makeOfferRepository(httpClient: env.httpClient)
        )
    }
}
