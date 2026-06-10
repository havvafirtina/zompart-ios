//
//  AuthLogoutScope.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// Scope of a logout operation. Values match the Supabase edge function
/// contract, which also accepts `global` and `others` — unused by this app.
enum AuthLogoutScope: String, Encodable, Sendable {
    case local
}
