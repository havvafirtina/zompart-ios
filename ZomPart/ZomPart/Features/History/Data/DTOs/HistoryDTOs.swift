//
//  HistoryDTOs.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

// MARK: - Shared sub-object DTOs

struct HistoryVehicleSummaryDTO: Decodable, Sendable {
        let id: String
        let make: String
        let model: String
        let year: Int

        func toModel() -> HistoryVehicleSummaryDomain {
                HistoryVehicleSummaryDomain(id: id, make: make, model: model, year: year)
        }
}

struct HistoryPartSummaryDTO: Decodable, Sendable {
        let id: String
        let name: String
        let partNumber: String
        let thumbnailUrl: String?

        private enum CodingKeys: String, CodingKey {
                case id, name
                case partNumber = "part_number"
                case thumbnailUrl = "thumbnail_url"
        }

        func toModel() -> HistoryPartSummaryDomain {
                HistoryPartSummaryDomain(id: id, name: name, partNumber: partNumber, thumbnailUrl: thumbnailUrl)
        }
}

// MARK: - Single scan DTOs

struct ScanDetailItemDTO: Decodable, Sendable {
        let id: String
        let state: String
        let inputType: String?
        let inputText: String?
        let aiStatus: String?
        let createdAt: String
        let updatedAt: String
        let vehicleId: String?

        private enum CodingKeys: String, CodingKey {
                case id, state
                case inputType = "input_type"
                case inputText = "input_text"
                case aiStatus  = "ai_status"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
                case vehicleId = "vehicle_id"
        }

        func toModel() -> ScanDetailItemDomain {
                ScanDetailItemDomain(
                        id: id,
                        state: state,
                        inputType: inputType,
                        inputText: inputText,
                        aiStatus: aiStatus.flatMap { ScanAiStatusDomain(rawValue: $0) },
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        vehicleId: vehicleId
                )
        }
}

struct ScanArtifactDTO: Decodable, Sendable {
        let id: String
        let artifactType: String?
        let ocrRawText: String?
        let thumbnailUrl: String?

        private enum CodingKeys: String, CodingKey {
                case id
                case artifactType = "artifact_type"
                case ocrRawText   = "ocr_raw_text"
                case thumbnailUrl = "thumbnail_url"
        }

        func toModel() -> ScanArtifactDomain {
                ScanArtifactDomain(
                        id: id,
                        artifactType: artifactType.flatMap { ScanArtifactTypeDomain(rawValue: $0) },
                        ocrRawText: ocrRawText,
                        thumbnailUrl: thumbnailUrl
                )
        }
}

/// DTO for the `data` field inside the single-scan response.
struct ScanDetailDataDTO: ResponseProtocol {
        typealias ModelType = ScanDetailDomain

        let scan: ScanDetailItemDTO
        let vehicle: HistoryVehicleSummaryDTO?
        let artifacts: [ScanArtifactDTO]
        let selectedPart: HistoryPartSummaryDTO?

        private enum CodingKeys: String, CodingKey {
                case scan, vehicle, artifacts
                case selectedPart = "selected_part"
        }

        func toModel() -> ScanDetailDomain {
                ScanDetailDomain(
                        scan: scan.toModel(),
                        vehicle: vehicle?.toModel(),
                        artifacts: artifacts.map { $0.toModel() },
                        selectedPart: selectedPart?.toModel()
                )
        }
}

// MARK: - History list DTOs

struct HistoryScanItemDTO: Decodable, Sendable {
        let id: String
        let state: String
        let createdAt: String
        let vehicle: HistoryVehicleSummaryDTO?
        let selectedPart: HistoryPartSummaryDTO?

        private enum CodingKeys: String, CodingKey {
                case id, state, vehicle
                case createdAt    = "created_at"
                case selectedPart = "selected_part"
        }

        func toModel() -> HistoryScanSummaryDomain {
                HistoryScanSummaryDomain(
                        id: id,
                        state: state,
                        createdAt: createdAt,
                        vehicle: vehicle?.toModel(),
                        selectedPart: selectedPart?.toModel()
                )
        }
}

struct HistoryPaginationDTO: Decodable, Sendable {
        let total: Int
        let limit: Int
        let offset: Int
        let hasMore: Bool

        private enum CodingKeys: String, CodingKey {
                case total, limit, offset
                case hasMore = "has_more"
        }

        func toModel() -> HistoryPaginationDomain {
                HistoryPaginationDomain(total: total, limit: limit, offset: offset, hasMore: hasMore)
        }
}

/// DTO for the `data` field inside the history-list response.
struct HistoryListDataDTO: ResponseProtocol {
        typealias ModelType = HistoryPageDomain

        let scans: [HistoryScanItemDTO]
        let pagination: HistoryPaginationDTO

        func toModel() -> HistoryPageDomain {
                HistoryPageDomain(
                        scans: scans.map { $0.toModel() },
                        pagination: pagination.toModel()
                )
        }
}
