import Foundation

extension String {

    /// Re-cases shouty vendor data for display: "FORD" → "Ford",
    /// "ALFA ROMEO" → "Alfa Romeo", "MERCEDES-BENZ" → "Mercedes-Benz".
    ///
    /// Deliberately conservative — a token is only re-cased when it is all
    /// uppercase letters AND longer than three characters:
    /// - short tokens are treated as acronyms ("BMW", "VW", "KIA" stay as-is)
    /// - tokens with digits are model codes ("XC60", "V70" stay as-is)
    /// - mixed-case tokens are already deliberate ("Focus" stays as-is)
    /// Locale is pinned to en_US_POSIX so a Turkish system locale never turns
    /// "I" into "ı" while re-casing.
    var displayCased: String {
        let posix = Locale(identifier: "en_US_POSIX")

        func recase(_ token: Substring) -> String {
            let isRecasable = token.count > 3
                && token.allSatisfy(\.isLetter)
                && String(token) == token.uppercased(with: posix)
            guard isRecasable else { return String(token) }
            let lowered = token.lowercased(with: posix)
            return lowered.prefix(1).uppercased(with: posix) + lowered.dropFirst()
        }

        return split(separator: " ", omittingEmptySubsequences: false)
            .map { word in
                word.split(separator: "-", omittingEmptySubsequences: false)
                    .map(recase)
                    .joined(separator: "-")
            }
            .joined(separator: " ")
    }
}
