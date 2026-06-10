import Foundation

@MainActor
@Observable
final class HistoryListViewModel {

    private(set) var state: ViewState<[HistoryScanSummaryDomain]> = .idle
    private(set) var scans: [HistoryScanSummaryDomain] = []
    private(set) var pagination: HistoryPaginationDomain?
    private(set) var isLoadingMore = false

    private let vehicleId: String?
    private let historyRepository: HistoryRepositoryProtocol
    private let pageSize = 20

    init(vehicleId: String? = nil, historyRepository: HistoryRepositoryProtocol) {
        self.vehicleId = vehicleId
        self.historyRepository = historyRepository
    }

    func loadInitial() async {
        if !scans.isEmpty { return await refresh() }
        state = .loading
        do {
            let page = try await historyRepository.fetchHistory(
                vehicleId: vehicleId, limit: pageSize, offset: 0
            )
            scans = page.scans
            pagination = page.pagination
            state = page.scans.isEmpty ? .empty : .loaded(page.scans)
        } catch is CancellationError {
            // Cancelled mid-load (view disappeared). Reset to .idle so the
            // cached VM's next .task run reloads instead of spinning forever.
            if case .loading = state { state = .idle }
        } catch let error as HistoryError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    func refresh() async {
        do {
            let page = try await historyRepository.fetchHistory(
                vehicleId: vehicleId, limit: pageSize, offset: 0
            )
            scans = page.scans
            pagination = page.pagination
            state = page.scans.isEmpty ? .empty : .loaded(page.scans)
        } catch {
            // refresh silently fails — keep existing data
        }
    }

    func loadMore() async {
        guard let pagination, pagination.hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let page = try await historyRepository.fetchHistory(
                vehicleId: vehicleId, limit: pageSize, offset: scans.count
            )
            scans.append(contentsOf: page.scans)
            self.pagination = page.pagination
            state = .loaded(scans)
        } catch {
            // silently fail on load more
        }
        isLoadingMore = false
    }
}
