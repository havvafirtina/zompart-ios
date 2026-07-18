import SwiftUI
import SBDesignSystem

struct EmailOTPAuthView: View {

    let viewModel: EmailOTPAuthViewModel

    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var intent: AuthOTPIntent = .signup

    var body: some View {
        ScrollView {
            VStack {
                header
                intentPicker
                fields
                sendButton
                errorMessage
            }
            .sbPadding(.large)
        }
        .background(Color.sbSurfacePrimary)
        .disabled(viewModel.state == .loading)
    }

    private var header: some View {
        VStack {
            LogoSubtitleView()
                .frame(width: 220)

            Text(Localized.Auth.title.localizedKey)
                .font(.sbTitleSemiboldXLarge)
                .foregroundStyle(Color.sbTextPrimary)

            Text(Localized.Auth.subtitle.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .sbVerticalPadding(.xLarge)
    }

    private var intentPicker: some View {
        Picker("", selection: $intent) {
            Text(Localized.Auth.intentSignup.localizedKey)
                .tag(AuthOTPIntent.signup)
            Text(Localized.Auth.intentLogin.localizedKey)
                .tag(AuthOTPIntent.login)
        }
        .pickerStyle(.segmented)
        .sbVerticalPadding(.medium)
    }

    private var fields: some View {
        VStack {
            TextField(Localized.Auth.emailPlaceholder.localized, text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.sbBodyRegularDefault)
                .sbPadding(.medium)
                .background(Color.sbSurfaceSecondary)
                .sbCornerRadius(.medium)

            if intent == .signup {
                TextField(Localized.Auth.firstNamePlaceholder.localized, text: $firstName)
                    .textContentType(.givenName)
                    .font(.sbBodyRegularDefault)
                    .sbPadding(.medium)
                    .background(Color.sbSurfaceSecondary)
                    .sbCornerRadius(.medium)

                TextField(Localized.Auth.lastNamePlaceholder.localized, text: $lastName)
                    .textContentType(.familyName)
                    .font(.sbBodyRegularDefault)
                    .sbPadding(.medium)
                    .background(Color.sbSurfaceSecondary)
                    .sbCornerRadius(.medium)
            }
        }
    }

    private var sendButton: some View {
        Button {
            Task {
                await viewModel.sendOTP(
                    email: email,
                    intent: intent,
                    firstName: intent == .signup ? firstName : nil,
                    lastName: intent == .signup ? lastName : nil
                )
            }
        } label: {
            Group {
                if viewModel.state == .loading {
                    ProgressView()
                        .tint(Color.sbTextOnAccent)
                } else {
                    Text(Localized.Auth.sendOTP.localizedKey)
                }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbTextOnAccent)
            .frame(maxWidth: .infinity)
            .sbControlHeight(.regular)
            .background(Color.sbAccentPrimary)
            .sbCornerRadius(.default)
        }
        .disabled(email.isEmpty)
        .sbVerticalPadding(.large)
    }

    @ViewBuilder
    private var errorMessage: some View {
        if case .error(let message) = viewModel.state {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(message)
            }
            .font(.sbBodyRegularSmall)
            .foregroundStyle(Color.sbStatusError)
            .sbPadding(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sbStatusErrorSubtle)
            .sbCornerRadius(.medium)
        }
    }
}
