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
/// Mirrors `ScanPartSummaryDomain` and `OfferPartSummaryDomain`; keep all three
/// in sync when Layer 1 evolves.
struct HistoryPartSummaryDomain: Equatable, Sendable {
    let id: String
    let name: String
    let nameTr: String?
    let nameSv: String?
    let partNumber: String
    let thumbnailUrl: String?
    // Layer 1 canonical enrichment
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

    var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier
        switch lang {
        case "tr": return nameTr ?? name
        case "sv": return nameSv ?? name
        default: return name
        }
    }

    var displayImageUrl: String? {
        imageUrl ?? thumbnailUrl
    }
}
