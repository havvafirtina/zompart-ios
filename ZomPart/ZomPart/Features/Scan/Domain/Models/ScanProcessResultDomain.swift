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

struct ScanPartSummaryDomain: Equatable, Sendable {
        let id: String
        let name: String
        let nameTr: String?
        let nameSv: String?
        let partNumber: String
        let thumbnailUrl: String?

        var localizedName: String {
                let lang = Locale.current.language.languageCode?.identifier
                switch lang {
                case "tr": return nameTr ?? name
                case "sv": return nameSv ?? name
                default: return name
                }
        }
}

struct ScanAlternativeDomain: Equatable, Hashable, Sendable {
        let name: String
        let partNumber: String
        let confidence: Double
}

struct ScanQuestionDomain: Equatable, Sendable {
        let id: String
        let question: String
        let options: [String]
}
