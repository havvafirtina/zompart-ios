import Foundation
import SBNetworking

extension HistoryError {

    var localizedMessage: String {
        switch self {
        case .scanNotFound:
            return Localized.Error.scanNotFound.localized
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
