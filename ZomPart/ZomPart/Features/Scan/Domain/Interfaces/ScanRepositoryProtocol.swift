//
//  ScanRepositoryProtocol.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Domain interface for scan session management and part identification.
/// Implemented by `ScanRepository` in the Data layer.
protocol ScanRepositoryProtocol: Sendable {

    /// Creates a new scan or resumes an existing pending one.
    /// Pass `startOver: true` to delete the pending scan and start fresh.
    func startScan(
        vehicleId: String,
        inputType: ScanInputTypeDomain,
        userDescription: String?,
        ocrTexts: [String],
        startOver: Bool
    ) async throws -> ScanDomain

    /// Returns signed upload URLs for photos. PHOTO scans only; max 8 per scan.
    func getUploadURLs(scanId: String, contentTypes: [String]) async throws -> [ScanUploadUrlItemDomain]

    /// Uploads photo data to the signed URLs obtained from `getUploadURLs`.
    /// `onPhotoUploaded` is invoked on the main actor after every successful
    /// per-photo PUT with the running count (1-based), enabling incremental
    /// UI progress instead of a single 0→100 jump.
    func uploadPhotos(
        scanId: String,
        photosData: [Data],
        onPhotoUploaded: (@Sendable @MainActor (Int) -> Void)?
    ) async throws

    /// Runs AI processing on the scan. Returns one of three outcomes.
    func processScan(scanId: String) async throws -> ScanProcessResultDomain

    /// Selects a part candidate from DISAMBIGUATION state (`SELECT_PART`).
    func selectPart(scanId: String, partCandidateId: String) async throws -> ScanFeedbackResultDomain

    /// Resolves a user-typed part/OE number on the same scan (`MANUAL_SEARCH`).
    /// Allowed from any state except PROCESSING; on success the scan moves to
    /// OFFERS_READY. Throws `ScanError.partLookupFailed` when the number
    /// cannot be resolved (the scan keeps its previous state and can retry).
    func manualSearch(scanId: String, query: String) async throws -> ScanFeedbackResultDomain
}
