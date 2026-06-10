import Foundation
import UIKit

@MainActor
@Observable
final class ScanInputViewModel {

    let mode: ScanInputMode
    private(set) var state: ViewState<ScanDomain> = .idle
    var photos: [UIImage] = []
    var ocrTexts: [String] = []
    var inputText = ""
    private(set) var uploadProgress: Double = 0
    private(set) var uploadedCount: Int = 0

    private let vehicleId: String
    private let scanRepository: ScanRepositoryProtocol
    private let onScanCreated: (ScanDomain) -> Void
    @ObservationIgnored private var analyzeTask: Task<Void, Never>?

    init(
        mode: ScanInputMode,
        vehicleId: String,
        scanRepository: ScanRepositoryProtocol,
        onScanCreated: @escaping (ScanDomain) -> Void
    ) {
        self.mode = mode
        self.vehicleId = vehicleId
        self.scanRepository = scanRepository
        self.onScanCreated = onScanCreated
    }

    var hasInput: Bool {
        !photos.isEmpty || !ocrTexts.isEmpty || !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Submit-eligibility differs by mode:
    /// - .photo: at least one photo is required (description is optional).
    /// - .text:  a non-empty text query is required.
    var canAnalyze: Bool {
        switch mode {
        case .photo: return !photos.isEmpty
        case .text:  return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var totalPhotos: Int { photos.count }

    func addPhoto(_ image: UIImage) {
        guard photos.count < 8 else { return }
        photos.append(image)
    }

    func addOCRText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !ocrTexts.contains(trimmed) else { return }
        ocrTexts.append(trimmed)
    }

    func removeOCRText(at index: Int) {
        guard ocrTexts.indices.contains(index) else { return }
        ocrTexts.remove(at: index)
    }

    func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        photos.remove(at: index)
    }

    func onAnalyzeTapped() {
        analyzeTask?.cancel()
        analyzeTask = Task { await analyze() }
    }

    /// Cancels an in-flight analyze when the screen goes away, so a finished
    /// upload can no longer yank the user into the scan flow from another tab.
    func onDisappear() {
        analyzeTask?.cancel()
        analyzeTask = nil
    }

    func analyze() async {
        state = .loading
        do {
            let scan = try await runScan(startOver: false)
            state = .loaded(scan)
            onScanCreated(scan)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch ScanError.photoLimitReached {
            // The resumed pending scan already holds the photo quota, so
            // re-uploading the on-screen set can never succeed — retrying
            // would loop on PHOTO_LIMIT_REACHED forever. The user's intent
            // is to analyze what's on screen: start over (the backend
            // deletes the stuck pending scan) and upload the current set.
            await analyzeStartingOver()
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    private func analyzeStartingOver() async {
        do {
            let scan = try await runScan(startOver: true)
            state = .loaded(scan)
            onScanCreated(scan)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    private func runScan(startOver: Bool) async throws -> ScanDomain {
        // input_type is locked at entry. The old behavior of computing it
        // from `photos.isEmpty` at submission silently swapped modes —
        // e.g. opening "Search by text" then taking a photo would still
        // send PHOTO. Now the user's chosen mode is the source of truth.
        let inputType = mode.asNetworkType
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let description: String? = text.isEmpty ? nil : text

        var scan = try await scanRepository.startScan(
            vehicleId: vehicleId,
            inputType: inputType,
            userDescription: description,
            ocrTexts: ocrTexts,
            startOver: startOver
        )

        // scan-start can resume a pending scan. One that has already been
        // processed cannot take new photos or another process call, so a
        // fresh analysis requires starting over.
        if !startOver, scan.state == .disambiguation || scan.state == .offersReady {
            scan = try await scanRepository.startScan(
                vehicleId: vehicleId,
                inputType: inputType,
                userDescription: description,
                ocrTexts: ocrTexts,
                startOver: true
            )
        }

        if mode == .photo && !photos.isEmpty {
            try await uploadPhotos(scanId: scan.scanId)
        }
        return scan
    }

    private func uploadPhotos(scanId: String) async throws {
        uploadedCount = 0
        uploadProgress = 0

        let photosData: [Data] = photos.compactMap { photo in
            photo.resizedToLongEdge(1024)?.jpegData(compressionQuality: 0.8)
        }
        let total = photosData.count
        guard total > 0 else { return }

        try await scanRepository.uploadPhotos(scanId: scanId, photosData: photosData) { uploaded in
            self.uploadedCount = uploaded
            self.uploadProgress = Double(uploaded) / Double(total)
        }
    }
}
