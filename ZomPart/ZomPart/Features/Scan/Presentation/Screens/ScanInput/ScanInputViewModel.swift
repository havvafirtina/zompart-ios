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
    private let ocrService: OCRServiceProtocol
    private let onScanCreated: (ScanDomain) -> Void

    init(
        mode: ScanInputMode,
        vehicleId: String,
        scanRepository: ScanRepositoryProtocol,
        ocrService: OCRServiceProtocol,
        onScanCreated: @escaping (ScanDomain) -> Void
    ) {
        self.mode = mode
        self.vehicleId = vehicleId
        self.scanRepository = scanRepository
        self.ocrService = ocrService
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

    func analyze() async {
        state = .loading
        do {
            // input_type is locked at entry. The old behavior of computing it
            // from `photos.isEmpty` at submission silently swapped modes —
            // e.g. opening "Search by text" then taking a photo would still
            // send PHOTO. Now the user's chosen mode is the source of truth.
            let inputType = mode.asNetworkType
            let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            let description: String? = text.isEmpty ? nil : text

            let scan = try await scanRepository.startScan(
                vehicleId: vehicleId,
                inputType: inputType,
                userDescription: description,
                ocrTexts: ocrTexts,
                startOver: false
            )

            if mode == .photo && !photos.isEmpty {
                try await uploadPhotos(scanId: scan.scanId)
            }

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
