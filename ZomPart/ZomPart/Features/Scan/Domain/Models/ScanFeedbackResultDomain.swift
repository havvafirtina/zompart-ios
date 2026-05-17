//
//  ScanFeedbackResultDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct ScanFeedbackResultDomain: Equatable, Sendable {
        let scanId: String
        let state: ScanStateDomain
        let nextAction: ScanNextActionDomain
}
