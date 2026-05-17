import SwiftUI
import SBDesignSystem

struct ProfileMainView: View {

    @Bindable var viewModel: ProfileMainViewModel
    let themeManager: ThemeManager
    let onTheme: () -> Void
    let onLanguage: () -> Void
    let onAbout: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        List {
            userInfoSection
            appearanceSection
            languageSection
            aboutSection
            accountSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Tab.profile.localized)
        .alert(
            Localized.Profile.logoutConfirmTitle.localized,
            isPresented: $viewModel.showLogoutConfirm
        ) {
            Button(Localized.Common.cancel.localized, role: .cancel) {}
            Button(Localized.Profile.logout.localized, role: .destructive) {
                Task { await viewModel.confirmLogout() }
            }
        } message: {
            Text(Localized.Profile.logoutConfirmMessage.localizedKey)
        }
        .disabled(viewModel.isLoggingOut)
    }

    // MARK: - User Info

    private var userInfoSection: some View {
        Section(Localized.Profile.userInfo.localized) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.sbAccentPrimary)

                VStack(alignment: .leading) {
                    if !viewModel.userName.isEmpty {
                        Text(viewModel.userName)
                            .font(.sbBodySemiboldDefault)
                            .foregroundStyle(Color.sbTextPrimary)
                    }

                    Text(viewModel.userEmail)
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbTextSecondary)
                }
            }
            .listRowBackground(Color.sbSurfaceSecondary)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section(Localized.Profile.appearance.localized) {
            Button {
                onTheme()
            } label: {
                HStack {
                    Label(Localized.Profile.theme.localized, systemImage: "paintpalette.fill")
                        .foregroundStyle(Color.sbTextPrimary)
                    Spacer()
                    Text(themeManager.currentTheme.rawValue.capitalized)
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbTextSecondary)
                    Image(systemName: "chevron.right")
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(Color.sbTextTertiary)
                }
            }
            .listRowBackground(Color.sbSurfaceSecondary)

            HStack {
                Label(Localized.Profile.appearanceMode.localized, systemImage: "circle.lefthalf.filled")
                    .foregroundStyle(Color.sbTextPrimary)
                Spacer()
                Picker("", selection: Binding(
                    get: { themeManager.appearancePreference },
                    set: { themeManager.appearancePreference = $0 }
                )) {
                    Text(Localized.Profile.system.localizedKey).tag(SBAppearancePreference.system)
                    Text(Localized.Profile.light.localizedKey).tag(SBAppearancePreference.light)
                    Text(Localized.Profile.dark.localizedKey).tag(SBAppearancePreference.dark)
                }
                .pickerStyle(.menu)
            }
            .listRowBackground(Color.sbSurfaceSecondary)
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        Section(Localized.Profile.language.localized) {
            Button {
                onLanguage()
            } label: {
                HStack {
                    Label(Localized.Profile.language.localized, systemImage: "globe")
                        .foregroundStyle(Color.sbTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(Color.sbTextTertiary)
                }
            }
            .listRowBackground(Color.sbSurfaceSecondary)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section(Localized.Profile.about.localized) {
            Button {
                onAbout()
            } label: {
                HStack {
                    Label(Localized.Profile.about.localized, systemImage: "info.circle")
                        .foregroundStyle(Color.sbTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(Color.sbTextTertiary)
                }
            }
            .listRowBackground(Color.sbSurfaceSecondary)
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section(Localized.Profile.account.localized) {
            Button {
                viewModel.requestLogout()
            } label: {
                Label(Localized.Profile.logout.localized, systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(Color.sbStatusError)
            }
            .listRowBackground(Color.sbSurfaceSecondary)

            Button {
                onDeleteAccount()
            } label: {
                Label(Localized.Profile.deleteAccount.localized, systemImage: "trash")
                    .foregroundStyle(Color.sbStatusError)
            }
            .listRowBackground(Color.sbSurfaceSecondary)
        }
    }
}
