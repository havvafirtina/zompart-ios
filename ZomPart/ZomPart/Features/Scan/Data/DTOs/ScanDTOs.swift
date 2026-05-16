//
//  ScanDTOs.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - scan-start

struct ScanStartDataDTO: ResponseProtocol {
    typealias ModelType = ScanDomain

    let scanId: String
    let state: String
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case scanId    = "scan_id"
        case state
        case createdAt = "created_at"
    }

    func toModel() -> ScanDomain {
        ScanDomain(
            scanId: scanId,
            state: ScanStateDomain(rawValue: state) ?? .inputCollected,
            createdAt: createdAt
        )
    }
}

// MARK: - scan-upload-url

struct ScanUploadUrlItemDTO: Decodable, Sendable {
    let photoId: String
    let uploadUrl: String
    let storagePath: String
    let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case photoId     = "photo_id"
        case uploadUrl   = "upload_url"
        case storagePath = "storage_path"
        case expiresIn   = "expires_in"
    }

    func toModel() -> ScanUploadUrlItemDomain {
        ScanUploadUrlItemDomain(
            photoId: photoId,
            uploadUrl: uploadUrl,
            storagePath: storagePath,
            expiresIn: expiresIn
        )
    }
}

struct ScanUploadUrlDataDTO: ResponseProtocol {
    typealias ModelType = [ScanUploadUrlItemDomain]

    let items: [ScanUploadUrlItemDTO]

    func toModel() -> [ScanUploadUrlItemDomain] {
        items.map { $0.toModel() }
    }
}

// MARK: - scan-process

struct ScanPartSummaryDTO: Decodable, Sendable {
    let id: String
    let name: String
    let partNumber: String
    let thumbnailUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id, name
        case partNumber  = "part_number"
        case thumbnailUrl = "thumbnail_url"
    }

    func toModel() -> ScanPartSummaryDomain {
        ScanPartSummaryDomain(id: id, name: name, partNumber: partNumber, thumbnailUrl: thumbnailUrl)
    }
}

struct ScanAlternativeDTO: Decodable, Sendable {
    let name: String
    let partNumber: String
    let confidence: Double

    private enum CodingKeys: String, CodingKey {
        case name, confidence
        case partNumber = "part_number"
    }

    func toModel() -> ScanAlternativeDomain {
        ScanAlternativeDomain(name: name, partNumber: partNumber, confidence: confidence)
    }
}

struct ScanQuestionDTO: Decodable, Sendable {
    let id: String
    let question: String
    let options: [String]

    func toModel() -> ScanQuestionDomain {
        ScanQuestionDomain(id: id, question: question, options: options)
    }
}

/// DTO for the `data` field inside the scan-process response.
/// All state-specific fields are optional; `toModel()` branches on `state`.
struct ScanProcessDataDTO: ResponseProtocol {
    typealias ModelType = ScanProcessResultDomain

    let scanId: String
    let state: String
    let nextAction: String
    let part: ScanPartSummaryDTO?
    let alternatives: [ScanAlternativeDTO]?
    let questions: [ScanQuestionDTO]?
    let reason: String?

    private enum CodingKeys: String, CodingKey {
        case scanId      = "scan_id"
        case state
        case nextAction  = "next_action"
        case part, alternatives, questions, reason
    }

    func toModel() -> ScanProcessResultDomain {
        switch state {
        case ScanStateDomain.offersReady.rawValue:
            guard let part else { return .failed(scanId: scanId, reason: "missing_part") }
            return .offersReady(scanId: scanId, part: part.toModel())
        case ScanStateDomain.disambiguation.rawValue:
            return .disambiguation(
                scanId: scanId,
                alternatives: (alternatives ?? []).map { $0.toModel() },
                questions: (questions ?? []).map { $0.toModel() }
            )
        default:
            return .failed(scanId: scanId, reason: reason ?? "unknown")
        }
    }
}

// MARK: - scan-feedback

struct ScanFeedbackDataDTO: ResponseProtocol {
    typealias ModelType = ScanFeedbackResultDomain

    let scanId: String
    let state: String
    let nextAction: String

    private enum CodingKeys: String, CodingKey {
        case scanId     = "scan_id"
        case state
        case nextAction = "next_action"
    }

    func toModel() -> ScanFeedbackResultDomain {
        ScanFeedbackResultDomain(
            scanId: scanId,
            state: ScanStateDomain(rawValue: state) ?? .offersReady,
            nextAction: ScanNextActionDomain(rawValue: nextAction) ?? .showOffers
        )
    }
}

// MARK: - scan-delete

struct ScanDeleteDataDTO: ResponseProtocol {
    typealias ModelType = Bool

    let deleted: Bool

    func toModel() -> Bool { deleted }
}
