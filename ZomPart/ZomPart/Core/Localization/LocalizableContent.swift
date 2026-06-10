import SwiftUI

protocol LocalizableContent: RawRepresentable where RawValue == String {
    var localized: String { get }
    var localizedKey: LocalizedStringKey { get }
    func localized(_ arguments: CVarArg...) -> String
}

extension LocalizableContent {

    var localized: String {
        String(
            localized: String.LocalizationValue(rawValue),
            table: "Localizable",
            bundle: .main
        )
    }

    var localizedKey: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    func localized(_ arguments: CVarArg...) -> String {
        let format = String(
            localized: String.LocalizationValue(rawValue),
            table: "Localizable",
            bundle: .main
        )
        return String(format: format, arguments: arguments)
    }
}
