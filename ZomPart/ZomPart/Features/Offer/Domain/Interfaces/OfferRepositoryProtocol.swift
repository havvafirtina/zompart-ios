//
//  OfferRepositoryProtocol.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Domain interface for offer listing and click tracking.
/// Implemented by `OfferRepository` in the Data layer.
protocol OfferRepositoryProtocol: Sendable {

        /// Returns offers for the given scan, sorted by the specified strategy.
        /// Returns an empty list (not an error) when no offers exist yet.
        func listOffers(scanId: String, sort: OfferSortDomain) async throws -> OfferListDomain

        /// Records an offer click and returns the UTM-tracked redirect URL.
        func recordClick(offerId: String, scanId: String) async throws -> OfferClickResultDomain
}
