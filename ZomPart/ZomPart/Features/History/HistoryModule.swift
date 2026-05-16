//
//  HistoryModule.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Static factory that wires History feature dependencies.
/// Called from the composition root; no state of its own.
enum HistoryModule {

    static func makeHistoryRepository(httpClient: HTTPClient) -> HistoryRepositoryProtocol {
        HistoryRepository(client: httpClient)
    }
}
