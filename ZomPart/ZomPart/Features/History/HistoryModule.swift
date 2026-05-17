import Foundation
import SBNetworking

enum HistoryModule {

    static func makeHistoryRepository(httpClient: HTTPClient) -> HistoryRepositoryProtocol {
        HistoryRepository(client: httpClient)
    }

    @MainActor
    static func makeHistoryListViewModel(
        env: AppEnvironment,
        vehicleId: String? = nil
    ) -> HistoryListViewModel {
        HistoryListViewModel(
            vehicleId: vehicleId,
            historyRepository: makeHistoryRepository(httpClient: env.httpClient)
        )
    }

    @MainActor
    static func makeScanDetailViewModel(
        env: AppEnvironment,
        scanId: String
    ) -> ScanDetailViewModel {
        ScanDetailViewModel(
            scanId: scanId,
            historyRepository: makeHistoryRepository(httpClient: env.httpClient)
        )
    }
}
