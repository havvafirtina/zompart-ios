//
//  APIEnvelope.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Generic wrapper for the standard Supabase edge-function response shape:
/// `{ "success": Bool, "data": T?, "meta": APIMeta? }`.
///
/// `T` is the inner DTO that conforms to `ResponseProtocol`.
/// The envelope itself conforms to `ResponseProtocol` so it can be used
/// directly as an `Endpoint.ResponseType`.
struct APIEnvelope<T: ResponseProtocol>: ResponseProtocol {
    typealias ModelType = T.ModelType

    let success: Bool
    let data: T?
    let meta: APIMeta?

    func toModel() -> T.ModelType {
        guard let data else {
            fatalError("APIEnvelope.toModel() called without data. Check success flag before calling.")
        }
        return data.toModel()
    }
}
