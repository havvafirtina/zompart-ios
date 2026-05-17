import SwiftUI
import SBDesignSystem

struct DeleteAccountView: View {

    @Bindable var viewModel: DeleteAccountViewModel

    var body: some View {
        ScrollView {
            VStack {
                switch viewModel.phase {
                case .confirm:
                    confirmPhase
                case .otpSent:
                    otpPhase
                case .deleting:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sbPadding(.large)
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Profile.deleteAccount.localized)
        .disabled(viewModel.state == .loading)
    }

    private var confirmPhase: some View {
        VStack {
            Spacer().frame(height: 40)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.sbStatusWarning)

            Text(Localized.Profile.deleteConfirmTitle.localizedKey)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)
                .sbVerticalPadding(.medium)

            Text(Localized.Profile.deleteConfirmMessage.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.requestDeletion() }
            } label: {
                Group {
                    if viewModel.state == .loading {
                        ProgressView().tint(.white)
                    } else {
                        Text(Localized.Profile.deleteAccount.localizedKey)
                    }
                }
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .sbControlHeight(.regular)
                .background(Color.sbStatusError)
                .sbCornerRadius(.default)
            }
            .sbVerticalPadding(.xLarge)

            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbStatusError)
            }
        }
    }

    private var otpPhase: some View {
        VStack {
            Spacer().frame(height: 40)

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbAccentPrimary)

            Text(Localized.Profile.deleteOTPSent.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)
                .sbVerticalPadding(.medium)

            TextField(Localized.Auth.otpPlaceholder.localized, text: $viewModel.otpCode)
                .keyboardType(.numberPad)
                .font(.sbTitleSemiboldLarge)
                .multilineTextAlignment(.center)
                .sbPadding(.large)
                .background(Color.sbSurfaceSecondary)
                .sbCornerRadius(.medium)

            Button {
                Task { await viewModel.confirmDeletion() }
            } label: {
                Group {
                    if viewModel.state == .loading {
                        ProgressView().tint(.white)
                    } else {
                        Text(Localized.Common.confirm.localizedKey)
                    }
                }
                .font(.sbBodySemiboldDefault)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .sbControlHeight(.regular)
                .background(Color.sbStatusError)
                .sbCornerRadius(.default)
            }
            .disabled(viewModel.otpCode.isEmpty)
            .sbVerticalPadding(.large)

            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbStatusError)
            }
        }
    }
}
