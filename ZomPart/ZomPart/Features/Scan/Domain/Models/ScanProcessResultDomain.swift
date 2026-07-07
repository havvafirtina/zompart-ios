//
//  ScanProcessResultDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

enum ScanNextActionDomain: String, Equatable, Sendable {
    case showOffers      = "SHOW_OFFERS"
    case showAlternatives = "SHOW_ALTERNATIVES"
    case manualSearch    = "MANUAL_SEARCH"
    case processScan     = "PROCESS_SCAN"
}

/// Why the scan needs the user to choose between candidates.
/// Backend sends `disambiguation_type`; older payloads omit it, and any
/// unknown value degrades to `.criteria` (the generic chooser UI).
enum DisambiguationKindDomain: Equatable, Hashable, Sendable {
    /// TecDoc variant split (e.g. front vs rear axle) or AI alternatives.
    case criteria
    /// The identified part does not fit the selected vehicle; alternatives
    /// carry `vehicleCompatible` so the UI can offer "fits my car" vs
    /// "continue with the scanned part".
    case vehicleMismatch

    init(wireValue: String?) {
        self = wireValue == "VEHICLE_MISMATCH" ? .vehicleMismatch : .criteria
    }
}

/// Result returned by `processScan()`. Shape varies by AI outcome.
enum ScanProcessResultDomain: Equatable, Sendable {
    case offersReady(scanId: String, part: ScanPartSummaryDomain)
    case disambiguation(
        scanId: String,
        kind: DisambiguationKindDomain,
        /// English mismatch explanation from the AI (backend sends it only
        /// for VEHICLE_MISMATCH today). Displayed as-is — not localized.
        reason: String?,
        alternatives: [ScanAlternativeDomain],
        questions: [ScanQuestionDomain]
    )
    case failed(scanId: String, reason: String)
}

struct ScanPartSummaryDomain: Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let nameTr: String?
    let nameSv: String?
    let partNumber: String
    let thumbnailUrl: String?
    // Layer 1 canonical enrichment. Optional because:
    //  - AMBIGUOUS-path candidates haven't been resolved yet
    //  - Parts provider may return an empty canonical (e.g. unknown brand + no VIN)
    //  - Older backend versions don't return these fields
    let oemNumber: String?
    let mpn: String?
    let ean: String?
    let brand: String?
    let manufacturer: String?
    let crossReferences: [String]?
    let categoryTecdoc: String?
    /// True if Autodoc Article Details articleOemNo[].oemBrand matched the user's vehicle make;
    /// false if it explicitly didn't match; nil when no compatibility data was available.
    let vehicleCompatible: Bool?
    /// CDN URL of the part image. Use this for the trust-signal thumbnail
    /// on the scan-result/offers screens. Falls back to `thumbnailUrl` (legacy).
    let imageUrl: String?
    /// AI's overall confidence (0..1) for the CONFIDENT branch.
    let confidenceScore: Double?
    /// TecDoc part-type (GenArt) id; nil for rows predating the TecDoc cutover.
    let genericArticleId: Int?
    /// Distinguishing TecDoc attributes of the chosen article (max 12 server-side).
    let articleCriteria: [ScanArticleCriterionDomain]
    /// True when an explicit TecDoc §8.4 linkage proof was obtained
    /// (safety-critical parts). Distinct from `vehicleCompatible`.
    let fitmentConfirmed: Bool

    var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier
        switch lang {
        case "tr": return nameTr ?? name
        case "sv": return nameSv ?? name
        default: return name
        }
    }

    /// Best image URL available; prefers the new `imageUrl` field but falls
    /// back to the legacy `thumbnailUrl` for older responses.
    var displayImageUrl: String? {
        imageUrl ?? thumbnailUrl
    }
}

struct ScanArticleCriterionDomain: Equatable, Hashable, Sendable {
    let criteriaId: Int?
    let label: String
    let value: String
    let unit: String?

    /// "Fitting Position: Front Axle" / "Diameter: 280 mm" style display line.
    var displayText: String {
        let valueWithUnit = unit.map { "\(value) \($0)" } ?? value
        return "\(label): \(valueWithUnit)"
    }
}

struct ScanAlternativeDomain: Equatable, Hashable, Sendable {
    let name: String
    /// `part_candidates.id` UUID. Forwarded to `selectPart(partCandidateId:)`.
    /// Backend currently sends this as `part_number` on the wire — see
    /// `ScanAlternativeDTO` for the decode mapping.
    let id: String
    let confidence: Double
    /// VEHICLE_MISMATCH only: `true` = equivalent part that fits the user's
    /// vehicle, `false` = the scanned (incompatible) part; nil otherwise.
    let vehicleCompatible: Bool?

    init(name: String, id: String, confidence: Double, vehicleCompatible: Bool? = nil) {
        self.name = name
        self.id = id
        self.confidence = confidence
        self.vehicleCompatible = vehicleCompatible
    }
}

struct ScanQuestionDomain: Equatable, Hashable, Sendable {
    let id: String
    let question: String
    let options: [String]
}
