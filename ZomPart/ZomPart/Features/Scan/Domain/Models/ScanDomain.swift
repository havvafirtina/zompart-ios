//
//  ScanDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct ScanDomain: Equatable, Sendable {
    let scanId: String
    let state: ScanStateDomain
    let createdAt: String
}

enum ScanStateDomain: String, Equatable, Sendable {
    case inputCollected  = "INPUT_COLLECTED"
    case disambiguation  = "DISAMBIGUATION"
    case offersReady     = "OFFERS_READY"
    case failed          = "FAILED"
}

enum ScanInputTypeDomain: String, Encodable, Sendable {
    case photo = "PHOTO"
    case text  = "TEXT"
}

/// UI-level scan mode chosen by the user on the ScanHome screen. Locks the
/// behavior of ScanInputView so the photo flow and the text flow are visually
/// and functionally distinct. Maps 1:1 to ScanInputTypeDomain at network
/// boundary — backend treats the two as separate input types.
enum ScanInputMode: Equatable, Sendable {
    case photo  // Camera + gallery + OCR + optional clarifying description
    case text   // Single text field — part name or number, no photo controls

    var asNetworkType: ScanInputTypeDomain {
        switch self {
        case .photo: return .photo
        case .text:  return .text
        }
    }
}
