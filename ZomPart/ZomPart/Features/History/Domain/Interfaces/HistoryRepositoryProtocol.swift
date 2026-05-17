//
//  HistoryRepositoryProtocol.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Domain interface for scan history access.
/// Implemented by `HistoryRepository` in the Data layer.
protocol HistoryRepositoryProtocol: Sendable {

        /// Returns full details for a single scan owned by the user.
        func fetchScan(scanId: String) async throws -> ScanDetailDomain

        /// Returns a paginated list of the user's scans, newest first.
        /// - Parameters:
        ///   - vehicleId: Optional vehicle filter. Pass `nil` to return scans for all vehicles.
        ///   - limit: Page size (1–50). Defaults to 20 on the backend.
        ///   - offset: Pagination offset. Defaults to 0.
        func fetchHistory(vehicleId: String?, limit: Int, offset: Int) async throws -> HistoryPageDomain
}
