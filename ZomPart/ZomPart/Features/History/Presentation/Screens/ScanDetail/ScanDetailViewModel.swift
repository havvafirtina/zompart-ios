import Foundation

@MainActor
@Observable
final class ScanDetailViewModel {

    private(set) var state: ViewState<ScanDetailDomain> = .idle

    private let scanId: String
    private let historyRepository: HistoryRepositoryProtocol

    init(scanId: String, historyRepository: HistoryRepositoryProtocol) {
        self.scanId = scanId
        self.historyRepository = historyRepository
    }

    func load() async {
        state = .loading
        do {
            let detail = try await historyRepository.fetchScan(scanId: scanId)
            state = .loaded(detail)
        } catch {
            state = .error(Localized.Error.network.localized)
        }
    }
}
