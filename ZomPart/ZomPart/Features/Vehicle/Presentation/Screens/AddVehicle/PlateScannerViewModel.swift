import Foundation
import UIKit
import AVFoundation

@MainActor
@Observable
final class PlateScannerViewModel {

    private(set) var state: ViewState<VehicleResolveResultDomain> = .idle
    var manualPlate = ""

    private let vehicleRepository: VehicleRepositoryProtocol
    private let ocrService: OCRServiceProtocol
    private let cameraPermission: CameraPermissionManager
    private let onVehicleAdded: (String) -> Void

    init(
        vehicleRepository: VehicleRepositoryProtocol,
        ocrService: OCRServiceProtocol,
        cameraPermission: CameraPermissionManager,
        onVehicleAdded: @escaping (String) -> Void
    ) {
        self.vehicleRepository = vehicleRepository
        self.ocrService = ocrService
        self.cameraPermission = cameraPermission
        self.onVehicleAdded = onVehicleAdded
    }

    var cameraAuthorized: Bool {
        cameraPermission.status == .authorized
    }

    func requestCameraAccess() async -> Bool {
        await cameraPermission.requestAccessIfNeeded()
    }

    func processImage(_ image: UIImage) async {
        guard let cgImage = image.cgImage else { return }

        do {
            let texts = try await ocrService.recognizeText(in: cgImage)
            if let plate = extractPlate(from: texts) {
                manualPlate = plate
            }
        } catch {
            // OCR failed silently — user can still type manually
        }
        state = .idle
    }

    func resolveEnteredPlate() async {
        let plate = manualPlate.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !plate.isEmpty else { return }
        manualPlate = plate
        await resolvePlate(plate)
    }

    private func resolvePlate(_ plate: String) async {
        state = .loading
        do {
            let result = try await vehicleRepository.resolveByPlate(plate, countryCode: "SE")
            state = .loaded(result)
            try? await Task.sleep(for: .seconds(1.5))
            onVehicleAdded(result.vehicle.id)
        } catch let error as VehicleError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    private func extractPlate(from texts: [String]) -> String? {
        let platePattern = /[A-Z]{3}\s?\d{2}[A-Z0-9]/
        for text in texts {
            let cleaned = text.uppercased()
            if let match = cleaned.firstMatch(of: platePattern) {
                return String(match.output).replacingOccurrences(of: " ", with: "")
            }
        }
        return nil
    }
}
