import Foundation
import SBNetworking

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
