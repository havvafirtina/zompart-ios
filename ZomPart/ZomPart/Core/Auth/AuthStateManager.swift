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

    private let tokenProvider: ZomPartAuthTokenProvider
    private let featureFlags: FeatureFlagClient

    private static let onboardingCompletedKey = "onboarding_completed"

    init(tokenProvider: ZomPartAuthTokenProvider, featureFlags: FeatureFlagClient) {
        self.tokenProvider = tokenProvider
        self.featureFlags = featureFlags

        let onboardingCompleted = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        let onboardingEnabled = featureFlags.bool(for: .onboardingEnabled)

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

    func didAuthenticate() {
        phase = .authenticated
    }

    func logout() {
        tokenProvider.clearTokens()
        phase = .unauthenticated
    }
}
