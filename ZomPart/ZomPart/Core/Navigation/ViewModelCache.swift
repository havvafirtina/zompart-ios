import Foundation

@MainActor
@Observable
final class ViewModelCache {

    private var historyListVMs: [String: HistoryListViewModel] = [:]
    private var scanDetailVMs: [String: ScanDetailViewModel] = [:]
    private var offersListVMs: [String: OffersListViewModel] = [:]

    func historyListVM(env: AppEnvironment, vehicleId: String? = nil) -> HistoryListViewModel {
        let key = vehicleId ?? "all"
        if let existing = historyListVMs[key] { return existing }
        let vm = HistoryModule.makeHistoryListViewModel(env: env, vehicleId: vehicleId)
        historyListVMs[key] = vm
        return vm
    }

    func scanDetailVM(env: AppEnvironment, scanId: String) -> ScanDetailViewModel {
        if let existing = scanDetailVMs[scanId] { return existing }
        let vm = HistoryModule.makeScanDetailViewModel(env: env, scanId: scanId)
        scanDetailVMs[scanId] = vm
        return vm
    }

    func offersListVM(env: AppEnvironment, scanId: String) -> OffersListViewModel {
        if let existing = offersListVMs[scanId] { return existing }
        let vm = OfferModule.makeOffersListViewModel(env: env, scanId: scanId)
        offersListVMs[scanId] = vm
        return vm
    }

    func invalidateHistory() {
        historyListVMs.removeAll()
        scanDetailVMs.removeAll()
    }

    func invalidateScanDetail(scanId: String) {
        scanDetailVMs.removeValue(forKey: scanId)
        offersListVMs.removeValue(forKey: scanId)
    }

    func invalidateAll() {
        historyListVMs.removeAll()
        scanDetailVMs.removeAll()
        offersListVMs.removeAll()
    }
}
