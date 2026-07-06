import Foundation
import UIKit
import AVFoundation

/// TecDoc VRM-capable plate markets. FI is licensed but currently rejected at
/// the TecAlliance account level (open vendor ticket) — it stays selectable and
/// starts working with no client change once the account is fixed; until then
/// the backend answers 503 and the UI shows a "coming soon" message.
enum PlateCountry: String, CaseIterable, Identifiable, Sendable {
    case sweden = "SE"
    case norway = "NO"
    case denmark = "DK"
    case finland = "FI"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .sweden: return "🇸🇪"
        case .norway: return "🇳🇴"
        case .denmark: return "🇩🇰"
        case .finland: return "🇫🇮"
        }
    }
}

@MainActor
@Observable
final class PlateScannerViewModel {

    private(set) var state: ViewState<VehicleResolveResultDomain> = .idle
    var manualPlate = ""
    var country: PlateCountry {
        didSet { UserDefaults.standard.set(country.rawValue, forKey: Self.countryKey) }
    }

    private let vehicleRepository: VehicleRepositoryProtocol
    private let ocrService: OCRServiceProtocol
    private let cameraPermission: CameraPermissionManager
    private let onVehicleAdded: (VehicleDomain) -> Void

    private static let countryKey = "plate_country"

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
        let stored = UserDefaults.standard.string(forKey: Self.countryKey)
        self.country = stored.flatMap(PlateCountry.init(rawValue:)) ?? .sweden
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
            let result = try await vehicleRepository.resolveByPlate(plate, countryCode: country.rawValue)
            state = .loaded(result)
            try? await Task.sleep(for: .seconds(1.5))
            onVehicleAdded(result.vehicle)
        } catch let error as VehicleError {
            // FI 503 is a known TecAlliance account limitation, not an outage.
            if error == .providerUnavailable, country == .finland {
                state = .error(Localized.Garage.errorFinlandComingSoon.localized)
            } else {
                state = .error(error.localizedMessage)
            }
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
