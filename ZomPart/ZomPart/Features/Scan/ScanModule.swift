//
//  ScanModule.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Static factory that wires Scan feature dependencies.
/// Called from the composition root; no state of its own.
enum ScanModule {

        static func makeScanRepository(httpClient: HTTPClient) -> ScanRepositoryProtocol {
                ScanRepository(client: httpClient)
        }
}
