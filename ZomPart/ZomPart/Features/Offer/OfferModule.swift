//
//  OfferModule.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Static factory that wires Offer feature dependencies.
/// Called from the composition root; no state of its own.
enum OfferModule {

        static func makeOfferRepository(httpClient: HTTPClient) -> OfferRepositoryProtocol {
                OfferRepository(client: httpClient)
        }
}
