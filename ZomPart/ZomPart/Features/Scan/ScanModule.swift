import Foundation
import SBNetworking

enum ScanModule {

    static func makeScanRepository(httpClient: HTTPClient) -> ScanRepositoryProtocol {
        ScanRepository(client: httpClient)
    }

    @MainActor
    static func makeScanHomeViewModel(env: AppEnvironment) -> ScanHomeViewModel {
        ScanHomeViewModel(
            vehicleRepository: VehicleModule.makeVehicleRepository(httpClient: env.httpClient)
        )
    }

    @MainActor
    static func makeScanInputViewModel(
        env: AppEnvironment,
        vehicleId: String,
        onScanCreated: @escaping (ScanDomain) -> Void
    ) -> ScanInputViewModel {
        ScanInputViewModel(
            vehicleId: vehicleId,
            scanRepository: makeScanRepository(httpClient: env.httpClient),
            ocrService: VisionOCRService(),
            onScanCreated: onScanCreated
        )
    }

    @MainActor
    static func makeScanProcessingViewModel(
        env: AppEnvironment,
        scanId: String,
        onResult: @escaping (ScanProcessResultDomain) -> Void
    ) -> ScanProcessingViewModel {
        ScanProcessingViewModel(
            scanId: scanId,
            scanRepository: makeScanRepository(httpClient: env.httpClient),
            onResult: onResult
        )
    }

    @MainActor
    static func makeDisambiguationViewModel(
        env: AppEnvironment,
        scanId: String,
        alternatives: [ScanAlternativeDomain],
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) -> DisambiguationViewModel {
        DisambiguationViewModel(
            scanId: scanId,
            alternatives: alternatives,
            scanRepository: makeScanRepository(httpClient: env.httpClient),
            onResolved: onResolved
        )
    }
}
