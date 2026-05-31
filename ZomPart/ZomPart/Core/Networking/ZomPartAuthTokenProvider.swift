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

    var hasStoredTokens: Bool { accessToken != nil }

    private let lock = OSAllocatedUnfairLock(initialState: TokenState())
    private let urlSession: URLSession
    private let tokenPersistence: TokenPersistence

    private static let supabasePublishableKey: String = {
        PlistReader.value(for: "SUPABASE_PUBLISHABLE_KEY")
    }()

    private static let scheme: String = {
        PlistReader.value(for: "SUPABASE_API_SCHEME")
    }()

    private static let baseURL: String = {
        PlistReader.value(for: "SUPABASE_URL")
    }()

    init(
        tokenPersistence: TokenPersistence = KeychainTokenStore(),
        urlSession: URLSession = .shared
    ) {
        self.tokenPersistence = tokenPersistence
        self.urlSession = urlSession

        if let storedAccess = tokenPersistence.loadAccessToken(),
          let storedRefresh = tokenPersistence.loadRefreshToken() {
            self.lock.withLock {
                $0.accessToken = storedAccess
                $0.refreshToken = storedRefresh
            }
        }
    }

    func updateTokens(accessToken: String, refreshToken: String) {
        lock.withLock {
            $0.accessToken = accessToken
            $0.refreshToken = refreshToken
        }
        tokenPersistence.save(accessToken: accessToken, refreshToken: refreshToken)
    }

    func clearTokens() {
        lock.withLock {
            $0.accessToken = nil
            $0.refreshToken = nil
        }
        tokenPersistence.clear()
    }

    /// Register a callback fired when a refresh attempt fails and the
    /// session is therefore invalid. AuthStateManager wires this to
    /// route the UI back to the login screen.
    func setOnAuthInvalidated(_ callback: @escaping @Sendable () -> Void) {
        lock.withLock { $0.onAuthInvalidated = callback }
    }

    private func notifyAuthInvalidated() {
        let callback = lock.withLock { $0.onAuthInvalidated }
        callback?()
    }

    func refresh() async throws {
        let pending: Task<Void, any Error>? = lock.withLock { $0.pendingRefresh }
        if let pending {
            try await pending.value
            return
        }

        let task = Task { [self] in
            defer { lock.withLock { $0.pendingRefresh = nil } }

            guard let currentRefreshToken = refreshToken else {
                throw HTTPClientError.unauthorized
            }

            guard let url = URL(string: "\(Self.scheme)://\(Self.baseURL)/functions/v1/auth-refresh") else {
                throw HTTPClientError.unauthorized
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Self.supabasePublishableKey, forHTTPHeaderField: "apikey")

            let body = ["refresh_token": currentRefreshToken]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                clearTokens()
                notifyAuthInvalidated()
                throw HTTPClientError.unauthorized
            }

            let decoded = try JSONDecoder().decode(RefreshEnvelope.self, from: data)
            guard decoded.success, let tokenData = decoded.data else {
                clearTokens()
                notifyAuthInvalidated()
                throw HTTPClientError.unauthorized
            }

            updateTokens(accessToken: tokenData.access_token, refreshToken: tokenData.refresh_token)
        }

        lock.withLock { $0.pendingRefresh = task }
        try await task.value
    }

    private struct TokenState {
        var accessToken: String?
        var refreshToken: String?
        var onAuthInvalidated: (@Sendable () -> Void)?
        var pendingRefresh: Task<Void, any Error>?
    }

    private struct RefreshEnvelope: Decodable {
        let success: Bool
        let data: RefreshData?
    }

    private struct RefreshData: Decodable {
        let access_token: String
        let refresh_token: String
    }
}
