//
//  ZomPartAuthTokenProvider.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import os
import SBNetworking

/// App-level token provider that supplies the Supabase API key on every request
/// and stores session tokens after successful authentication.
///
/// Mutable token state is protected by `OSAllocatedUnfairLock` so the provider
/// is genuinely thread-safe and can conform to `Sendable` without `@unchecked`.
final class ZomPartAuthTokenProvider: AuthTokenProvider, @unchecked Sendable {

    var apiKey: String? { Self.supabasePublishableKey }

    var accessToken: String? { lock.withLock { $0.accessToken } }
    var refreshToken: String? { lock.withLock { $0.refreshToken } }

    private let lock = OSAllocatedUnfairLock(initialState: TokenState())

    private static let supabasePublishableKey: String = {
        PlistReader.value(for: "SUPABASE_PUBLISHABLE_KEY")
    }()

    func updateTokens(accessToken: String, refreshToken: String) {
        lock.withLock {
            $0.accessToken = accessToken
            $0.refreshToken = refreshToken
        }
    }

    func clearTokens() {
        lock.withLock {
            $0.accessToken = nil
            $0.refreshToken = nil
        }
    }

    private struct TokenState {
        var accessToken: String?
        var refreshToken: String?
    }
}
