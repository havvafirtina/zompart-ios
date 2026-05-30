import Foundation

@Observable
@MainActor
final class AuthStateManager {

    enum AuthPhase: Equatable {
        case onboarding
        case unauthenticated
        case authenticated
    }

    private(set) var phase: AuthPhase
    private(set) var userEmail: String = ""
    private(set) var userName: String = ""

    private let tokenProvider: ZomPartAuthTokenProvider
    private let featureFlags: FeatureFlagClient

    private static let onboardingCompletedKey = "onboarding_completed"
    private static let launchedBeforeKey = "app_launched_before"

    init(tokenProvider: ZomPartAuthTokenProvider, featureFlags: FeatureFlagClient) {
        self.tokenProvider = tokenProvider
        self.featureFlags = featureFlags

        // iOS Keychain entries survive app deletion, so a reinstall would
        // resurrect tokens whose backend user may no longer exist. UserDefaults
        // is wiped on uninstall, so we use a "launched before" flag to detect
        // fresh installs and clear stale Keychain tokens accordingly.
        let isFreshInstall = !UserDefaults.standard.bool(forKey: Self.launchedBeforeKey)
        if isFreshInstall {
            tokenProvider.clearTokens()
            UserDefaults.standard.set(true, forKey: Self.launchedBeforeKey)
        }

        let onboardingCompleted = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        let onboardingEnabled = featureFlags.bool(for: .onboardingEnabled)

        self.userEmail = UserDefaults.standard.string(forKey: "user_email") ?? ""
        self.userName = UserDefaults.standard.string(forKey: "user_name") ?? ""

        if !onboardingCompleted && onboardingEnabled {
            self.phase = .onboarding
        } else if tokenProvider.hasStoredTokens {
            self.phase = .authenticated
        } else {
            self.phase = .unauthenticated
        }
    }

    func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        if tokenProvider.hasStoredTokens {
            phase = .authenticated
        } else {
            phase = .unauthenticated
        }
    }

    func didAuthenticate(email: String = "", name: String = "") {
        if !email.isEmpty {
            userEmail = email
            UserDefaults.standard.set(email, forKey: "user_email")
        }
        if !name.isEmpty {
            userName = name
            UserDefaults.standard.set(name, forKey: "user_name")
        }
        phase = .authenticated
    }

    func logout() {
        tokenProvider.clearTokens()
        userEmail = ""
        userName = ""
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_name")
        phase = .unauthenticated
    }

    /// Called when the network layer detects that the current session is no
    /// longer valid (refresh attempt failed). The token provider has already
    /// cleared its own state — we just need to mirror that into the UI
    /// auth phase so RootView routes back to the login screen.
    func handleAuthInvalidated() {
        userEmail = ""
        userName = ""
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_name")
        phase = .unauthenticated
    }
}
