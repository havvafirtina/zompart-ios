import Foundation
import SwiftUI
import SBNetworking

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
    onVehicleAdded: @escaping () -> Void
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
    onVehicleAdded: @escaping () -> Void
  ) -> PlateScannerViewModel {
    PlateScannerViewModel(
      vehicleRepository: makeVehicleRepository(httpClient: env.httpClient),
      ocrService: VisionOCRService(),
      cameraPermission: CameraPermissionManager(),
      onVehicleAdded: onVehicleAdded
    )
  }

  @MainActor
  static func makeManualWizardViewModel(
    env: AppEnvironment,
    onVehicleAdded: @escaping () -> Void
  ) -> ManualWizardViewModel {
    ManualWizardViewModel(
      vehicleRepository: makeVehicleRepository(httpClient: env.httpClient),
      onVehicleAdded: onVehicleAdded
    )
  }
}
