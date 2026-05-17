//
//  HistoryPageDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct HistoryPageDomain: Equatable, Sendable {
        let scans: [HistoryScanSummaryDomain]
        let pagination: HistoryPaginationDomain
}

/// Lightweight scan item returned in the history list.
struct HistoryScanSummaryDomain: Equatable, Sendable {
        let id: String
        let state: String
        let createdAt: String
        let vehicle: HistoryVehicleSummaryDomain?
        let selectedPart: HistoryPartSummaryDomain?
}

struct HistoryPaginationDomain: Equatable, Sendable {
        let total: Int
        let limit: Int
        let offset: Int
        let hasMore: Bool
}
