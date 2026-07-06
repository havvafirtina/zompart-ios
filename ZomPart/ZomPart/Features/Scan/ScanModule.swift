import Foundation
import SBNetworking

extension ScanError {

    var localizedMessage: String {
        switch self {
        case .network:
            return Localized.Error.network.localized
        case .tokenExpired:
            return Localized.Error.tokenExpired.localized
        case .rateLimitExceeded(let retryAfter):
            return retryAfter.map { Localized.Error.rateLimitRetryIn.localized($0) }
                ?? Localized.Error.rateLimitExceeded.localized
        case .scanNotFound:
            return Localized.Error.scanNotFound.localized
        case .vehicleNotFound:
            return Localized.Error.vehicleNotFound.localized
        case .invalidState:
            return Localized.Error.invalidState.localized
        case .conflict:
            return Localized.Error.conflict.localized
        case .noPhotosUploaded:
            return Localized.Error.noPhotosUploaded.localized
        case .photoLimitReached:
            return Localized.Error.photoLimitReached.localized
        case .photoUploadFailed:
            return Localized.Error.photoUploadFailed.localized
        case .aiTemporarilyUnavailable:
            return Localized.Error.aiTemporarilyUnavailable.localized
        case .partLookupFailed:
            return Localized.Error.partLookupFailed.localized
        default:
            return Localized.Error.unknown.localized
        }
    }
}

enum ScanModule {

    static func makeScanRepository(httpClient: HTTPClient) -> ScanRepositoryProtocol {
        ScanRepository(client: httpClient)
    }

    @MainActor
    static func makeScanHomeViewModel(
        env: AppEnvironment,
        vehicleRepository: VehicleRepositoryProtocol
    ) -> ScanHomeViewModel {
        ScanHomeViewModel(
            vehicleRepository: vehicleRepository
        )
    }

    @MainActor
    static func makeScanInputViewModel(
        env: AppEnvironment,
        mode: ScanInputMode,
        vehicleId: String,
        onScanCreated: @escaping (ScanDomain) -> Void
    ) -> ScanInputViewModel {
        ScanInputViewModel(
            mode: mode,
            vehicleId: vehicleId,
            scanRepository: makeScanRepository(httpClient: env.httpClient),
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
        questions: [ScanQuestionDomain] = [],
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) -> DisambiguationViewModel {
        DisambiguationViewModel(
            scanId: scanId,
            alternatives: alternatives,
            questions: questions,
            scanRepository: makeScanRepository(httpClient: env.httpClient),
            onResolved: onResolved
        )
    }

    @MainActor
    static func makeScanFailedViewModel(
        env: AppEnvironment,
        scanId: String,
        onResolved: @escaping (ScanFeedbackResultDomain) -> Void
    ) -> ScanFailedViewModel {
        ScanFailedViewModel(
            scanId: scanId,
            scanRepository: makeScanRepository(httpClient: env.httpClient),
            onResolved: onResolved
        )
    }
}
