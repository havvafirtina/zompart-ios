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
        self._authStateManager = State(
            wrappedValue: AuthStateManager(
                tokenProvider: env.tokenProvider,
                featureFlags: env.featureFlags
            )
        )
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
                )
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
