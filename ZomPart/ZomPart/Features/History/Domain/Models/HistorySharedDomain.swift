//
//  HistorySharedDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Minimal vehicle summary returned inside history items and single scan.
/// Defined independently — History must not import the Vehicle feature.
struct HistoryVehicleSummaryDomain: Equatable, Sendable {
        let id: String
        let make: String
        let model: String
        let year: Int
}

/// Part summary returned as `selected_part` in history items and single scan.
/// Same shape as SelectedPartSummary in the backend contract.
/// Defined independently — History must not import Scan or Offer features.
struct HistoryPartSummaryDomain: Equatable, Sendable {
        let id: String
        let name: String
        let partNumber: String
        let thumbnailUrl: String?
}
