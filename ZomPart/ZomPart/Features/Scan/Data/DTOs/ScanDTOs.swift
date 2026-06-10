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
    let nameTr: String?
    let nameSv: String?
    let partNumber: String
    let thumbnailUrl: String?
    // Layer 1 canonical enrichment (all optional — null when AMBIGUOUS path
    // picked a candidate without running resolvePart, or when the parts
    // provider returned an empty canonical).
    let oemNumber: String?
    let mpn: String?
    let ean: String?
    let brand: String?
    let manufacturer: String?
    let crossReferences: [String]?
    let categoryTecdoc: String?
    let vehicleCompatible: Bool?
    let imageUrl: String?
    let confidenceScore: Double?

    private enum CodingKeys: String, CodingKey {
        case id, name, brand, manufacturer, mpn, ean
        case nameTr = "name_tr"
        case nameSv = "name_sv"
        case partNumber = "part_number"
        case thumbnailUrl = "thumbnail_url"
        case oemNumber = "oem_number"
        case crossReferences = "cross_references"
        case categoryTecdoc = "category_tecdoc"
        case vehicleCompatible = "vehicle_compatible"
        case imageUrl = "image_url"
        case confidenceScore = "confidence_score"
    }

    func toModel() -> ScanPartSummaryDomain {
        ScanPartSummaryDomain(
            id: id,
            name: name,
            nameTr: nameTr,
            nameSv: nameSv,
            partNumber: partNumber,
            thumbnailUrl: thumbnailUrl,
            oemNumber: oemNumber,
            mpn: mpn,
            ean: ean,
            brand: brand,
            manufacturer: manufacturer,
            crossReferences: crossReferences,
            categoryTecdoc: categoryTecdoc,
            vehicleCompatible: vehicleCompatible,
            imageUrl: imageUrl,
            confidenceScore: confidenceScore
        )
    }
}

struct ScanAlternativeDTO: Decodable, Sendable {
    let name: String
    /// Backend wire field is `part_number` for historical reasons, but the
    /// value is actually the `part_candidates.id` UUID. Decoded under the
    /// correct Swift name so callers can pass it to `selectPart(partCandidateId:)`
    /// without ambiguity. Do NOT rename the JSON key until the backend ships
    /// a coordinated change to send `id` instead.
    let id: String
    let confidence: Double

    private enum CodingKeys: String, CodingKey {
        case name, confidence
        case id = "part_number"
    }

    func toModel() -> ScanAlternativeDomain {
        ScanAlternativeDomain(name: name, id: id, confidence: confidence)
    }
}

struct ScanQuestionDTO: Decodable, Sendable {
    let id: String?
    let question: String
    let options: [String]

    private let stableId: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = try container.decodeIfPresent(String.self, forKey: .id)
        self.id = decodedId
        self.stableId = decodedId ?? UUID().uuidString
        self.question = try container.decode(String.self, forKey: .question)
        self.options = try container.decode([String].self, forKey: .options)
    }

    private enum CodingKeys: String, CodingKey {
        case id, question, options
    }

    func toModel() -> ScanQuestionDomain {
        ScanQuestionDomain(id: stableId, question: question, options: options)
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
