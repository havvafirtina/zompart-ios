import Foundation
import UIKit
import AVFoundation

@MainActor
@Observable
final class VINScannerViewModel {

    private(set) var state: ViewState<VehicleResolveResultDomain> = .idle
    var manualVIN = ""

    private let vehicleRepository: VehicleRepositoryProtocol
    private let ocrService: OCRServiceProtocol
    private let cameraPermission: CameraPermissionManager
    private let onVehicleAdded: (VehicleDomain) -> Void

    init(
        vehicleRepository: VehicleRepositoryProtocol,
        ocrService: OCRServiceProtocol,
        cameraPermission: CameraPermissionManager,
        onVehicleAdded: @escaping (VehicleDomain) -> Void
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
            if let vin = extractVIN(from: texts) {
                manualVIN = vin
            }
        } catch {
            // OCR failed silently — user can still type manually
        }
        state = .idle
    }

    func resolveEnteredVIN() async {
        let vin = manualVIN.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        // ISO 3779: I, O and Q are never valid in a VIN (0/1 confusion).
        guard vin.wholeMatch(of: Self.vinPattern) != nil else {
            state = .error(Localized.Garage.errorInvalidVIN.localized)
            return
        }
        manualVIN = vin
        await resolveVIN(vin)
    }

    private func resolveVIN(_ vin: String) async {
        state = .loading
        do {
            let result = try await vehicleRepository.resolveByVIN(vin, countryCode: "SE")
            state = .loaded(result)
            try? await Task.sleep(for: .seconds(1.5))
            onVehicleAdded(result.vehicle)
        } catch let error as VehicleError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    private static let vinPattern = /[A-HJ-NPR-Z0-9]{17}/

    private func extractVIN(from texts: [String]) -> String? {
        for text in texts {
            let cleaned = text.replacingOccurrences(of: " ", with: "").uppercased()
            if let match = cleaned.firstMatch(of: Self.vinPattern) {
                return String(match.output)
            }
        }
        return nil
    }
}
