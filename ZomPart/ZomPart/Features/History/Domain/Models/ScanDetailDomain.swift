//
//  ScanDetailDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Full scan detail returned by the single-scan mode of scan-get.
struct ScanDetailDomain: Equatable, Sendable {
        let scan: ScanDetailItemDomain
        let vehicle: HistoryVehicleSummaryDomain?
        let artifacts: [ScanArtifactDomain]
        let selectedPart: HistoryPartSummaryDomain?
}

struct ScanDetailItemDomain: Equatable, Sendable {
        let id: String
        let state: String
        let inputType: String?
        let inputText: String?
        let aiStatus: ScanAiStatusDomain?
        let createdAt: String
        let updatedAt: String
        let vehicleId: String?
}

enum ScanAiStatusDomain: String, Equatable, Sendable {
        case confident = "CONFIDENT"
        case ambiguous = "AMBIGUOUS"
        case needsInfo = "NEEDS_INFO"
        case failed    = "FAILED"
}

struct ScanArtifactDomain: Equatable, Sendable {
        let id: String
        let artifactType: ScanArtifactTypeDomain?
        let ocrRawText: String?
        let thumbnailUrl: String?
}

enum ScanArtifactTypeDomain: String, Equatable, Sendable {
        case photo     = "PHOTO"
        case ocrResult = "OCR_RESULT"
        case thumbnail = "THUMBNAIL"
        case qa        = "QA"
}
