//
//  AuthLogoutScope.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Scope of a logout operation. Values match the Supabase edge function contract.
enum AuthLogoutScope: String, Encodable, Sendable {
    case local
    case global
    case others
}
