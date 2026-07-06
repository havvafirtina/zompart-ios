import Foundation
import SwiftUI
import SBNetworking

extension VehicleError {

    var localizedMessage: String {
        switch self {
        case .invalidVIN:
            return Localized.Garage.errorInvalidVIN.localized
        case .invalidPlate:
            return Localized.Garage.errorInvalidPlate.localized
        case .invalidCountryCode:
            return Localized.Garage.errorInvalidCountry.localized
        case .vehicleNotFound:
            return Localized.Error.vehicleNotFound.localized
        case .tokenExpired:
            return Localized.Error.tokenExpired.localized
        case .rateLimitExceeded:
            return Localized.Error.rateLimitExceeded.localized
        case .providerUnavailable:
            return Localized.Garage.errorProviderUnavailable.localized
        case .network:
            return Localized.Error.network.localized
        default:
            return Localized.Error.unknown.localized
        }
    }
}

enum VehicleModule {

    static func makeVehicleRepository(httpClient: HTTPClient) -> VehicleRepositoryProtocol {
        VehicleRepository(client: httpClient)
    }

    @MainActor
    static func makeGarageListViewModel(env: AppEnvironment) -> GarageListViewModel {
        GarageListViewModel(
            vehicleRepository: makeVehicleRepository(httpClient: env.httpClient)
        )
    }

    @MainActor
    static func makeVINScannerViewModel(
        env: AppEnvironment,
        onVehicleAdded: @escaping (VehicleDomain) -> Void
    ) -> VINScannerViewModel {
        VINScannerViewModel(
            vehicleRepository: makeVehicleRepository(httpClient: env.httpClient),
            ocrService: VisionOCRService(),
            cameraPermission: CameraPermissionManager(),
            onVehicleAdded: onVehicleAdded
        )
    }

    @MainActor
    static func makePlateScannerViewModel(
        env: AppEnvironment,
        onVehicleAdded: @escaping (VehicleDomain) -> Void
    ) -> PlateScannerViewModel {
        PlateScannerViewModel(
            vehicleRepository: makeVehicleRepository(httpClient: env.httpClient),
            ocrService: VisionOCRService(),
            cameraPermission: CameraPermissionManager(),
            onVehicleAdded: onVehicleAdded
        )
    }
}
