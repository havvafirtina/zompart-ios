import Foundation

@MainActor
@Observable
final class ScanProcessingViewModel {

    private(set) var state: ViewState<ScanProcessResultDomain> = .idle
    private(set) var currentTip: String = ""

    private let scanId: String
    private let scanRepository: ScanRepositoryProtocol
    private let onResult: (ScanProcessResultDomain) -> Void

    private let tips: [Localized.Scan] = [
        .processingTip1, .processingTip2, .processingTip3, .processingTip4
    ]
    private var tipIndex = 0

    init(
        scanId: String,
        scanRepository: ScanRepositoryProtocol,
        onResult: @escaping (ScanProcessResultDomain) -> Void
    ) {
        self.scanId = scanId
        self.scanRepository = scanRepository
        self.onResult = onResult
        self.currentTip = tips.first?.localized ?? ""
    }

    func startProcessing() async {
        if case .loading = state { return }
        if case .loaded = state { return }
        state = .loading
        startTipRotation()

        do {
            let result = try await scanRepository.processScan(scanId: scanId)
            state = .loaded(result)
            onResult(result)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    private func startTipRotation() {
        Task {
            while state == .loading {
                try? await Task.sleep(for: .seconds(3))
                guard state == .loading else { break }
                tipIndex = (tipIndex + 1) % tips.count
                currentTip = tips[tipIndex].localized
            }
        }
    }
}
