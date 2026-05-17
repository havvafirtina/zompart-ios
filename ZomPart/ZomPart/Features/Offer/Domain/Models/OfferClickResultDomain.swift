//
//  OfferClickResultDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct OfferClickResultDomain: Equatable, Sendable {
        let clickId: String
        let offerId: String
        let scanId: String
        /// UTM-parametrized vendor redirect URL.
        let redirectUrl: String
        let tracked: Bool
}
