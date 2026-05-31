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

/// Result returned by `processScan()`. Shape varies by AI outcome.
enum ScanProcessResultDomain: Equatable, Sendable {
    case offersReady(scanId: String, part: ScanPartSummaryDomain)
    case disambiguation(scanId: String, alternatives: [ScanAlternativeDomain], questions: [ScanQuestionDomain])
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

struct ScanAlternativeDomain: Equatable, Hashable, Sendable {
    let name: String
    let partNumber: String
    let confidence: Double
}

struct ScanQuestionDomain: Equatable, Hashable, Sendable {
    let id: String
    let question: String
    let options: [String]
}
