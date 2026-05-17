import SwiftUI
import SBDesignSystem

struct LanguagePickerView: View {

    @State private var selectedLanguage: String
    @State private var showRestartAlert = false

    private let languages: [(code: String, name: String)] = [
        ("en", "English"),
        ("sv", "Svenska"),
        ("tr", "Türkçe")
    ]

    init() {
        let current = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        _selectedLanguage = State(initialValue: String(current))
    }

    var body: some View {
        List {
            ForEach(languages, id: \.code) { lang in
                Button {
                    selectLanguage(lang.code)
                } label: {
                    HStack {
                        Text(lang.name)
                            .font(.sbBodyRegularDefault)
                            .foregroundStyle(Color.sbTextPrimary)

                        Spacer()

                        if selectedLanguage == lang.code {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.sbAccentPrimary)
                        } else {
                            Image(systemName: "circle")
                                .font(.title3)
                                .foregroundStyle(Color.sbBorderSubtle)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.sbSurfaceSecondary)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Profile.language.localized)
        .alert(
            Localized.Profile.language.localized,
            isPresented: $showRestartAlert
        ) {
            Button(Localized.Common.ok.localized) {}
        } message: {
            Text(Localized.Profile.restartRequired.localizedKey)
        }
    }

    private func selectLanguage(_ code: String) {
        guard code != selectedLanguage else { return }
        selectedLanguage = code
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        showRestartAlert = true
    }
}
