import Foundation

@MainActor
@Observable
final class ScanFailedViewModel {

    private(set) var state: ViewState<ScanFeedbackResultDomain> = .idle
    var manualQuery = ""

    private let scanId: String
    private let scanRepository: ScanRepositoryProtocol
    private let onResolved: (ScanFeedbackResultDomain) -> Void

    init(
        scanId: String,
        scanRepository: ScanRepositoryProtocol,
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) {
        self.scanId = scanId
        self.scanRepository = scanRepository
        self.onResolved = onResolved
    }

    /// FAILED scans answer with `next_action: MANUAL_SEARCH` — resolving a
    /// typed part number on the same scan moves it straight to OFFERS_READY.
    /// On PART_LOOKUP_FAILED the scan keeps its state and the user can retry.
    func manualSearch() async {
        let query = manualQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        state = .loading
        do {
            let result = try await scanRepository.manualSearch(scanId: scanId, query: query)
            state = .loaded(result)
            onResolved(result)
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }
}
