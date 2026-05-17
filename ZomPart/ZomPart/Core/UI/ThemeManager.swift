import Foundation
import SBDesignSystem

@MainActor
@Observable
final class ThemeManager {

    var currentTheme: SBTheme {
        didSet {
            SBDesignSystemManager.shared.updateTheme(currentTheme)
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.themeKey)
        }
    }

    var appearancePreference: SBAppearancePreference {
        didSet {
            SBDesignSystemManager.shared.updateAppearance(appearancePreference)
            UserDefaults.standard.set(appearancePreference.rawValue, forKey: Self.appearanceKey)
        }
    }

    private static let themeKey = "selected_theme"
    private static let appearanceKey = "appearance_preference"

    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: Self.themeKey),
           let theme = SBTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .crimson
        }

        if let savedAppearance = UserDefaults.standard.string(forKey: Self.appearanceKey),
           let appearance = SBAppearancePreference(rawValue: savedAppearance) {
            self.appearancePreference = appearance
        } else {
            self.appearancePreference = .system
        }

        SBDesignSystemManager.shared.updateTheme(currentTheme)
        SBDesignSystemManager.shared.updateAppearance(appearancePreference)
    }
}
