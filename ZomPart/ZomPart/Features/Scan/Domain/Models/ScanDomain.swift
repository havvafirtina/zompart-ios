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
