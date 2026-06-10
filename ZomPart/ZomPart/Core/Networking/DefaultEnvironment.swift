//
//  DefaultEnvironment.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

struct DefaultEnvironment: HttpClientProtocol {

    private struct Keys {
        struct Supabase {
            static let scheme = "SUPABASE_API_SCHEME"
            static let url = "SUPABASE_URL"
        }

        static let appEnvironment = "APP_ENV"
    }

    private static let scheme: String = {
        PlistReader.value(for: Keys.Supabase.scheme)
    }()

    private static let baseURL: String = {
        PlistReader.value(for: Keys.Supabase.url)
    }()

    let environment: HTTPClientEnvironment
    let authTokenProvider: AuthTokenProvider?

    init(authTokenProvider: AuthTokenProvider) {
        self.environment = HTTPClientEnvironment(
            scheme: Self.scheme,
            baseURL: Self.baseURL
        )
        self.authTokenProvider = authTokenProvider
    }
}
