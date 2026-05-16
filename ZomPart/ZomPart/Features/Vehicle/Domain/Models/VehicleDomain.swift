//
//  VehicleDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct VehicleDomain: Equatable, Sendable {
    let id: String
    let make: String
    let model: String
    let year: Int?
    let engineCode: String?
    let trim: String?
    let resolveMethod: VehicleResolveMethodDomain
    let countryCode: String
    let vin: String?
    let plate: String?
}

enum VehicleResolveMethodDomain: String, Equatable, Sendable {
    case vin = "VIN"
    case plate = "PLATE"
    case person = "PERSON"
    case company = "COMPANY"
    case manual = "MANUAL"
}
