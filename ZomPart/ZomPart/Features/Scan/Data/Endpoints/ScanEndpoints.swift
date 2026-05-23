//
//  ScanEndpoints.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// ─────────────────────────────────────────
// MARK: - scan-start
// ─────────────────────────────────────────

struct ScanStartRequest: RequestProtocol {
        typealias EndpointType = ScanStartEndpoint
        let vehicleId: String
        let inputType: ScanInputTypeDomain
        let userDescription: String?
        let ocrTexts: [String]
        let startOver: Bool
        func toEndpoint() -> ScanStartEndpoint {
                ScanStartEndpoint(vehicleId: vehicleId, inputType: inputType, userDescription: userDescription, ocrTexts: ocrTexts, startOver: startOver)
        }
}

struct ScanStartEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<ScanStartDataDTO>
        let vehicleId: String
        let inputType: ScanInputTypeDomain
        let userDescription: String?
        let ocrTexts: [String]
        let startOver: Bool
        var path: String { "/functions/v1/scan-start" }
        var method: HTTPMethod { .post }
        var payload: Encodable? {
                ScanStartBody(vehicleId: vehicleId, inputType: inputType, userDescription: userDescription, ocrTexts: ocrTexts, startOver: startOver)
        }
}

private struct ScanStartBody: Encodable {
        let vehicleId: String
        let inputType: ScanInputTypeDomain
        let userDescription: String?
        let ocrTexts: [String]
        let startOver: Bool
        private enum CodingKeys: String, CodingKey {
                case vehicleId = "vehicle_id"
                case inputType = "input_type"
                case userDescription = "user_description"
                case ocrTexts = "ocr_texts"
                case startOver = "start_over"
        }
}

// ─────────────────────────────────────────
// MARK: - scan-upload-url
// ─────────────────────────────────────────

struct ScanUploadUrlRequest: RequestProtocol {
        typealias EndpointType = ScanUploadUrlEndpoint
        let scanId: String
        let contentTypes: [String]
        func toEndpoint() -> ScanUploadUrlEndpoint {
                ScanUploadUrlEndpoint(scanId: scanId, contentTypes: contentTypes)
        }
}

struct ScanUploadUrlEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<ScanUploadUrlDataDTO>
        let scanId: String
        let contentTypes: [String]
        var path: String { "/functions/v1/scan-upload-url" }
        var method: HTTPMethod { .post }
        var payload: Encodable? {
                ScanUploadUrlBody(
                        scanId: scanId,
                        files: contentTypes.map { ScanUploadFileItem(contentType: $0) }
                )
        }
}

private struct ScanUploadFileItem: Encodable {
        let contentType: String
        private enum CodingKeys: String, CodingKey { case contentType = "content_type" }
}

private struct ScanUploadUrlBody: Encodable {
        let scanId: String
        let files: [ScanUploadFileItem]
        private enum CodingKeys: String, CodingKey {
                case scanId = "scan_id"
                case files
        }
}

// ─────────────────────────────────────────
// MARK: - scan-process
// ─────────────────────────────────────────

struct ScanProcessRequest: RequestProtocol {
        typealias EndpointType = ScanProcessEndpoint
        let scanId: String
        func toEndpoint() -> ScanProcessEndpoint { ScanProcessEndpoint(scanId: scanId) }
}

struct ScanProcessEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<ScanProcessDataDTO>
        let scanId: String
        var path: String { "/functions/v1/scan-process" }
        var method: HTTPMethod { .post }
        var payload: Encodable? { ScanIdBody(scanId: scanId) }
}

// ─────────────────────────────────────────
// MARK: - scan-feedback (SELECT_PART only)
// ─────────────────────────────────────────

struct ScanSelectPartRequest: RequestProtocol {
        typealias EndpointType = ScanFeedbackEndpoint
        let scanId: String
        let partCandidateId: String
        func toEndpoint() -> ScanFeedbackEndpoint {
                ScanFeedbackEndpoint(scanId: scanId, partCandidateId: partCandidateId)
        }
}

struct ScanFeedbackEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<ScanFeedbackDataDTO>
        let scanId: String
        let partCandidateId: String
        var path: String { "/functions/v1/scan-feedback" }
        var method: HTTPMethod { .post }
        var payload: Encodable? {
                ScanFeedbackBody(scanId: scanId, action: "SELECT_PART", selectedPartId: partCandidateId)
        }
}

private struct ScanFeedbackBody: Encodable {
        let scanId: String
        let action: String
        let selectedPartId: String
        private enum CodingKeys: String, CodingKey {
                case scanId         = "scan_id"
                case action
                case selectedPartId = "selected_part_id"
        }
}

// ─────────────────────────────────────────
// MARK: - scan-delete
// ─────────────────────────────────────────

struct ScanDeleteRequest: RequestProtocol {
        typealias EndpointType = ScanDeleteEndpoint
        let scanId: String
        func toEndpoint() -> ScanDeleteEndpoint { ScanDeleteEndpoint(scanId: scanId) }
}

struct ScanDeleteEndpoint: Endpoint {
        typealias ResponseType = APIEnvelope<ScanDeleteDataDTO>
        let scanId: String
        var path: String { "/functions/v1/scan-delete" }
        var method: HTTPMethod { .post }
        var payload: Encodable? { ScanIdBody(scanId: scanId) }
}

// ─────────────────────────────────────────
// MARK: - Shared body
// ─────────────────────────────────────────

private struct ScanIdBody: Encodable {
        let scanId: String
        private enum CodingKeys: String, CodingKey { case scanId = "scan_id" }
}
