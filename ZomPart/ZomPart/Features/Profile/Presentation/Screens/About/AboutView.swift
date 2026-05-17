import SwiftUI
import SBDesignSystem

struct AboutView: View {

    @State private var safariUrl: IdentifiableURL?

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text(Localized.Profile.version.localizedKey)
                        .font(.sbBodyRegularDefault)
                        .foregroundStyle(Color.sbTextPrimary)
                    Spacer()
                    Text(appVersion)
                        .font(.sbBodyRegularDefault)
                        .foregroundStyle(Color.sbTextSecondary)
                }
                .listRowBackground(Color.sbSurfaceSecondary)
            }

            Section {
                Button {
                    safariUrl = IdentifiableURL(url: URL(string: "https://www.google.com")!)
                } label: {
                    HStack {
                        Label(Localized.Profile.privacyPolicy.localized, systemImage: "lock.shield")
                            .foregroundStyle(Color.sbTextPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.sbBodyRegularXSmall)
                            .foregroundStyle(Color.sbTextTertiary)
                    }
                }
                .listRowBackground(Color.sbSurfaceSecondary)

                Button {
                    safariUrl = IdentifiableURL(url: URL(string: "https://www.google.com")!)
                } label: {
                    HStack {
                        Label(Localized.Profile.termsOfService.localized, systemImage: "doc.text")
                            .foregroundStyle(Color.sbTextPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.sbBodyRegularXSmall)
                            .foregroundStyle(Color.sbTextTertiary)
                    }
                }
                .listRowBackground(Color.sbSurfaceSecondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Profile.about.localized)
        .sheet(item: $safariUrl) { item in
            SafariView(url: item.url)
        }
    }
}
