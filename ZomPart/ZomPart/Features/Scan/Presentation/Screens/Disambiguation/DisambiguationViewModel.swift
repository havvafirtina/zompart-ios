import Foundation

@MainActor
@Observable
final class DisambiguationViewModel {

    private(set) var state: ViewState<ScanFeedbackResultDomain> = .idle
    let kind: DisambiguationKindDomain
    /// English mismatch explanation from the backend (VEHICLE_MISMATCH only).
    let reason: String?
    let alternatives: [ScanAlternativeDomain]
    let questions: [ScanQuestionDomain]

    private let scanId: String
    private let scanRepository: ScanRepositoryProtocol
    private let onResolved: (ScanFeedbackResultDomain) -> Void

    init(
        scanId: String,
        kind: DisambiguationKindDomain = .criteria,
        reason: String? = nil,
        alternatives: [ScanAlternativeDomain],
        questions: [ScanQuestionDomain] = [],
        scanRepository: ScanRepositoryProtocol,
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) {
        self.scanId = scanId
        self.kind = kind
        self.reason = reason
        self.alternatives = alternatives
        self.questions = questions
        self.scanRepository = scanRepository
        self.onResolved = onResolved
    }

    var manualQuery = ""

    func selectPart(partCandidateId: String) async {
        state = .loading
        do {
            let result = try await scanRepository.selectPart(
                scanId: scanId,
                partCandidateId: partCandidateId
            )
            state = .loaded(result)
            onResolved(result)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    /// Fallback when none of the alternatives matches: resolve the user-typed
    /// part number on the same scan (MANUAL_SEARCH). On PART_LOOKUP_FAILED the
    /// scan keeps its DISAMBIGUATION state, so the user can retry or still
    /// pick an alternative.
    func manualSearch() async {
        let query = manualQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        state = .loading
        do {
            let result = try await scanRepository.manualSearch(scanId: scanId, query: query)
            state = .loaded(result)
            onResolved(result)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }
}
