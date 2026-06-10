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
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
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
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
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
        do {
            let contentTypes = photosData.map { _ in "image/jpeg" }
            let urlItems = try await getUploadURLs(scanId: scanId, contentTypes: contentTypes)

            let scheme: String = PlistReader.value(for: "SUPABASE_API_SCHEME")
            let host: String = PlistReader.value(for: "SUPABASE_URL")

            for (index, urlItem) in urlItems.enumerated() {
                guard index < photosData.count else { break }
                try Task.checkCancellation()

                let data = photosData[index]
                let fixedUrlString = Self.fixUploadUrl(urlItem.uploadUrl, scheme: scheme, host: host)
                guard let url = URL(string: fixedUrlString) else { throw ScanError.photoUploadFailed }

                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

                let (_, response) = try await URLSession.shared.upload(for: request, from: data)

                // URLSession only throws on transport failure; an expired
                // signed URL (60s TTL) comes back as an HTTP 403 that must
                // not be counted as a successful upload.
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw ScanError.photoUploadFailed
                }

                if let onPhotoUploaded {
                    await onPhotoUploaded(index + 1)
                }
            }
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
        } catch let e as URLError where e.code == .notConnectedToInternet || e.code == .networkConnectionLost {
            throw ScanError.network
        } catch let e as ScanError { throw e
        } catch { throw ScanError.unknown }
    }

    private static func fixUploadUrl(_ urlString: String, scheme: String, host: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        components.scheme = scheme
        components.host = host.components(separatedBy: ":").first
        if let portString = host.components(separatedBy: ":").last,
          let port = Int(portString), portString != host {
            components.port = port
        } else {
            // Configured host has no port — drop any port carried over from
            // the backend-issued URL (e.g. local 54321 fixed up to prod).
            components.port = nil
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
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
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
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
        } catch let e as ScanError { throw e
        } catch let e as HTTPClientError { throw Self.mapFeedbackError(e)
        } catch { throw ScanError.unknown }
    }

    // MARK: - Delete

    func deleteScan(scanId: String) async throws {
        do {
            let request = ScanDeleteRequest(scanId: scanId)
            _ = try await client.submitRequest(request: request)
        } catch is CancellationError { throw CancellationError()
        } catch let e as URLError where e.code == .cancelled { throw CancellationError()
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
            default: return .unknown
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
            default: return .unknown
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
            default: return .unknown
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
            default: return .unknown
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
            default: return .unknown
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
