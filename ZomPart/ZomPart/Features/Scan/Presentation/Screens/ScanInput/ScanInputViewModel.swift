import Foundation
import UIKit

@MainActor
@Observable
final class ScanInputViewModel {

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
        vehicleId: String,
        scanRepository: ScanRepositoryProtocol,
        ocrService: OCRServiceProtocol,
        onScanCreated: @escaping (ScanDomain) -> Void
    ) {
        self.vehicleId = vehicleId
        self.scanRepository = scanRepository
        self.ocrService = ocrService
        self.onScanCreated = onScanCreated
    }

    var hasInput: Bool {
        !photos.isEmpty || !ocrTexts.isEmpty || !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canAnalyze: Bool {
        !photos.isEmpty || !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            let inputType: ScanInputTypeDomain = photos.isEmpty ? .text : .photo
            let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            let description: String? = text.isEmpty ? nil : text

            let scan = try await scanRepository.startScan(
                vehicleId: vehicleId,
                inputType: inputType,
                userDescription: description,
                ocrTexts: ocrTexts,
                startOver: false
            )

            if !photos.isEmpty {
                try await uploadPhotos(scanId: scan.scanId)
            }

            state = .loaded(scan)
            onScanCreated(scan)
        } catch let error as ScanError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    private func uploadPhotos(scanId: String) async throws {
        let contentTypes = photos.map { _ in "image/jpeg" }
        let urlItems = try await scanRepository.getUploadURLs(
            scanId: scanId,
            contentTypes: contentTypes
        )

        uploadedCount = 0
        uploadProgress = 0

        let scheme: String = PlistReader.value(for: "SUPABASE_API_SCHEME")
        let host: String = PlistReader.value(for: "SUPABASE_URL")

        for (index, urlItem) in urlItems.enumerated() {
            guard index < photos.count,
                  let resized = photos[index].resizedToLongEdge(1024),
                  let data = resized.jpegData(compressionQuality: 0.8) else { continue }

            let fixedUrlString = fixUploadUrl(urlItem.uploadUrl, scheme: scheme, host: host)
            #if DEBUG
            print("[Upload] Original: \(urlItem.uploadUrl.prefix(60))...")
            print("[Upload] Fixed:    \(fixedUrlString.prefix(60))...")
            #endif
            guard let url = URL(string: fixedUrlString) else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

            let _ = try await URLSession.shared.upload(for: request, from: data)
            uploadedCount = index + 1
            uploadProgress = Double(uploadedCount) / Double(urlItems.count)
        }
    }

    private func fixUploadUrl(_ urlString: String, scheme: String, host: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        components.scheme = scheme
        components.host = host.components(separatedBy: ":").first
        if let portString = host.components(separatedBy: ":").last,
           let port = Int(portString), portString != host {
            components.port = port
        }
        return components.string ?? urlString
    }
}
