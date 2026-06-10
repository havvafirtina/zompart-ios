import Foundation

struct LocalFeatureFlagClient: FeatureFlagClient {

    func bool(for key: FeatureFlagKey) -> Bool {
        switch key {
        case .onboardingEnabled: true
        }
    }

    func int(for key: FeatureFlagKey) -> Int? {
        nil
    }

    func double(for key: FeatureFlagKey) -> Double? {
        nil
    }

    func string(for key: FeatureFlagKey) -> String? {
        nil
    }
}
