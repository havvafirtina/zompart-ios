//
//  ScanRepository.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Concrete repository that talks to the Supabase scan edge functions via `HTTPClient`.
/// Uses `actor` isolation to satisfy `Sendable`.
actor ScanRepository: ScanRepositoryProtocol {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: - Start

    func startScan(
        vehicleId: String,
        inputType: ScanInputTypeDomain,
        userDescription: String?,
        ocrTexts: [String],
        startOver: Bool
    ) async throws -> ScanDomain {
        do {
            let request = ScanStartRequest(
                vehicleId: vehicleId,
                inputType: inputType,
                userDescription: userDescription,
                ocrTexts: ocrTexts,
                startOver: startOver
            )
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapStartError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Upload URLs

    func getUploadURLs(scanId: String, contentTypes: [String]) async throws -> [ScanUploadUrlItemDomain] {
        do {
            let request = ScanUploadUrlRequest(scanId: scanId, contentTypes: contentTypes)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapUploadError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Upload Photos

    func uploadPhotos(
        scanId: String,
        photosData: [Data],
        onPhotoUploaded: (@Sendable @MainActor (Int) -> Void)? = nil
    ) async throws {
        let contentTypes = photosData.map { _ in "image/jpeg" }
        let urlItems = try await getUploadURLs(scanId: scanId, contentTypes: contentTypes)

        let scheme: String = PlistReader.value(for: "SUPABASE_API_SCHEME")
        let host: String = PlistReader.value(for: "SUPABASE_URL")

        for (index, urlItem) in urlItems.enumerated() {
            guard index < photosData.count else { break }
            try Task.checkCancellation()

            let data = photosData[index]
            let fixedUrlString = Self.fixUploadUrl(urlItem.uploadUrl, scheme: scheme, host: host)
            guard let url = URL(string: fixedUrlString) else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

            _ = try await URLSession.shared.upload(for: request, from: data)

            if let onPhotoUploaded {
                await onPhotoUploaded(index + 1)
            }
        }
    }

    private static func fixUploadUrl(_ urlString: String, scheme: String, host: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        components.scheme = scheme
        components.host = host.components(separatedBy: ":").first
        if let portString = host.components(separatedBy: ":").last,
          let port = Int(portString), portString != host {
            components.port = port
        }
        return components.string ?? urlString
    }

    // MARK: - Process

    func processScan(scanId: String) async throws -> ScanProcessResultDomain {
        do {
            let request = ScanProcessRequest(scanId: scanId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapProcessError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Feedback

    func selectPart(scanId: String, partCandidateId: String) async throws -> ScanFeedbackResultDomain {
        do {
            let request = ScanSelectPartRequest(scanId: scanId, partCandidateId: partCandidateId)
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw ScanError.emptyResponse }
            return envelope.toModel()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapFeedbackError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Delete

    func deleteScan(scanId: String) async throws {
        do {
            let request = ScanDeleteRequest(scanId: scanId)
            _ = try await client.submitRequest(request: request)
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapCommonError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Error mapping

    private static func mapStartError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .notFound: return .vehicleNotFound
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidUUID: return .invalidUUID
            default: return .invalidUUID
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapUploadError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidScanType: return .invalidScanType
            case .invalidMimeType: return .invalidMimeType
            case .photoLimitReached: return .photoLimitReached
            case .invalidUUID: return .invalidUUID
            default: return .invalidScanType
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapProcessError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 409, _): return .conflict
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidState: return .invalidState
            case .noPhotosUploaded: return .noPhotosUploaded
            case .invalidUUID: return .invalidUUID
            default: return .invalidState
            }
        case .serverError:
            // Backend already retries Gemini + falls back to OpenAI before
            // surfacing a 5xx. If we still got one, both AI providers are
            // unavailable — surface a transient-friendly error so the user
            // sees a "try again in a few seconds" message and a retry button.
            return .aiTemporarilyUnavailable
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapFeedbackError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidPart: return .invalidPart
            case .invalidAction: return .invalidAction
            case .invalidState: return .invalidState
            case .invalidUUID: return .invalidUUID
            default: return .invalidState
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapCommonError(_ e: HTTPClientError) -> ScanError {
        switch e {
        case .notFound: return .scanNotFound
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidUUID: return .invalidUUID
            default: return .invalidUUID
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
