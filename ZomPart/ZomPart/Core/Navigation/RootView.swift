import SwiftUI
import SBDesignSystem

struct RootView: View {

    let env: AppEnvironment
    @State private var authStateManager: AuthStateManager
    @State private var themeManager = ThemeManager()
    @State private var router = AppRouter()
    @State private var pendingVerifyEmail: String?
    @State private var pendingUserName: String?

    init(env: AppEnvironment) {
        self.env = env
        let manager = AuthStateManager(
            tokenProvider: env.tokenProvider,
            featureFlags: env.featureFlags
        )
        self._authStateManager = State(wrappedValue: manager)

        // Wire the network layer to notify the auth state manager when a
        // refresh attempt fails. Without this hook, stale tokens (e.g. after
        // a backend user wipe) would keep the UI on MainTabView while every
        // request fails — instead we route back to the login screen.
        env.tokenProvider.setOnAuthInvalidated { [weak manager] in
            Task { @MainActor in
                manager?.handleAuthInvalidated()
            }
        }
    }

    var body: some View {
        Group {
            switch authStateManager.phase {
            case .onboarding:
                OnboardingModule.makeOnboardingView {
                    authStateManager.markOnboardingComplete()
                }

            case .unauthenticated:
                authFlow

            case .authenticated:
                MainTabView(router: router, env: env, authStateManager: authStateManager, themeManager: themeManager)
            }
        }
        .animation(.default, value: authStateManager.phase)
        .onChange(of: authStateManager.phase) { _, newValue in
            if newValue != .authenticated {
                router.resetAll()
            }
        }
    }

    @ViewBuilder
    private var authFlow: some View {
        if let email = pendingVerifyEmail {
            OTPVerifyView(
                viewModel: AuthModule.makeOTPVerifyViewModel(
                    env: env,
                    email: email,
                    onVerified: { session in
                        env.tokenProvider.updateTokens(
                            accessToken: session.accessToken,
                            refreshToken: session.refreshToken
                        )
                        pendingVerifyEmail = nil
                        authStateManager.didAuthenticate(email: email, name: pendingUserName ?? "")
                    }
                ),
                onChangeEmail: {
                    pendingVerifyEmail = nil
                    pendingUserName = nil
                }
            )
        } else {
            EmailOTPAuthView(
                viewModel: AuthModule.makeEmailOTPAuthViewModel(
                    env: env,
                    onOTPSent: { email, name in
                        pendingVerifyEmail = email
                        pendingUserName = name
                    }
                )
            )
        }
    }
}
