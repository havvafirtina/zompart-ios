import Foundation

protocol FeatureFlagClient: Sendable {
  func bool(for key: FeatureFlagKey) -> Bool
  func int(for key: FeatureFlagKey) -> Int?
  func double(for key: FeatureFlagKey) -> Double?
  func string(for key: FeatureFlagKey) -> String?
}
