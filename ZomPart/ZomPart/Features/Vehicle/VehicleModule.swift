//
//  VehicleModule.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Static factory that wires Vehicle feature dependencies.
/// Called from the composition root; no state of its own.
enum VehicleModule {

    static func makeVehicleRepository(httpClient: HTTPClient) -> VehicleRepositoryProtocol {
        VehicleRepository(client: httpClient)
    }
}
