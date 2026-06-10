//
//  APIMeta.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Metadata returned by Supabase edge functions alongside every response.
struct APIMeta: Decodable, Sendable {
    let requestId: String
    let timestamp: String

    private enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case timestamp
    }
}
