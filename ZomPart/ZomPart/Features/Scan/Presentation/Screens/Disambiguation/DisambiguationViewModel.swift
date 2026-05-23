import Foundation

@MainActor
@Observable
final class DisambiguationViewModel {

    private(set) var state: ViewState<ScanFeedbackResultDomain> = .idle
    let alternatives: [ScanAlternativeDomain]

    private let scanId: String
    private let scanRepository: ScanRepositoryProtocol
    private let onResolved: (ScanFeedbackResultDomain) -> Void

    init(
        scanId: String,
        alternatives: [ScanAlternativeDomain],
        scanRepository: ScanRepositoryProtocol,
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) {
        self.scanId = scanId
        self.alternatives = alternatives
        self.scanRepository = scanRepository
        self.onResolved = onResolved
    }

    func selectPart(partCandidateId: String) async {
        state = .loading
        do {
            let result = try await scanRepository.selectPart(
                scanId: scanId,
                partCandidateId: partCandidateId
            )
            state = .loaded(result)
            onResolved(result)
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }
}
