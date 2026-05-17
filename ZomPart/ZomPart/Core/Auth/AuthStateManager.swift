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

    init(tokenProvider: ZomPartAuthTokenProvider, featureFlags: FeatureFlagClient) {
        self.tokenProvider = tokenProvider
        self.featureFlags = featureFlags

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
}
