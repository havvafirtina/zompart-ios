//
//  ZomPartApp.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import SwiftUI
import SBNetworking

@main
struct ZomPartApp: App {

    private let tokenProvider: ZomPartAuthTokenProvider
    private let httpClient: HTTPClient

    @State private var pendingVerifyEmail: String? = nil
    @State private var isAuthenticated = false

    init() {
        let tp = ZomPartAuthTokenProvider()
        let environment = DefaultEnvironment(authTokenProvider: tp)
        self.tokenProvider = tp
        self.httpClient = HTTPClient(client: environment)
    }

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
            } else if let email = pendingVerifyEmail {
                OTPVerifyView(
                    viewModel: AuthModule.makeOTPVerifyViewModel(
                        httpClient: httpClient,
                        email: email,
                        onVerified: { session in
                            tokenProvider.updateTokens(
                                accessToken: session.accessToken,
                                refreshToken: session.refreshToken
                            )
                            isAuthenticated = true
                        }
                    )
                )
            } else {
                EmailOTPAuthView(
                    viewModel: AuthModule.makeEmailOTPAuthViewModel(
                        httpClient: httpClient,
                        onOTPSent: { email in
                            pendingVerifyEmail = email
                        }
                    )
                )
            }
        }
    }
}
