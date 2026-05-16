//
//  OfferListDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct OfferListDomain: Equatable, Sendable {
    let scanId: String
    /// Nil when the scan has no selected part yet.
    let part: OfferPartSummaryDomain?
    let offers: [OfferDomain]
    let sortApplied: OfferSortDomain
    let totalCount: Int
}
