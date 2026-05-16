import SwiftUI
import SBDesignSystem

struct OTPVerifyView: View {

  @Bindable var viewModel: OTPVerifyViewModel

  var body: some View {
    ScrollView {
      VStack {
        header
        codeField
        verifyButton
        errorMessage
      }
      .sbPadding(.large)
    }
    .background(Color.sbSurfacePrimary)
    .disabled(viewModel.state == .loading)
  }

  private var header: some View {
    VStack {
      Image(systemName: "envelope.badge.fill")
        .font(.system(size: 48))
        .foregroundStyle(Color.sbAccentPrimary)

      Text(Localized.Auth.otpTitle.localizedKey)
        .font(.sbTitleSemiboldXLarge)
        .foregroundStyle(Color.sbTextPrimary)

      Text(Localized.Auth.otpSubtitle.localized(viewModel.email))
        .font(.sbBodyRegularDefault)
        .foregroundStyle(Color.sbTextSecondary)
        .multilineTextAlignment(.center)
    }
    .sbVerticalPadding(.xLarge)
  }

  private var codeField: some View {
    TextField(Localized.Auth.otpPlaceholder.localized, text: $viewModel.otpCode)
      .keyboardType(.numberPad)
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .font(.sbTitleSemiboldLarge)
      .multilineTextAlignment(.center)
      .sbPadding(.large)
      .background(Color.sbSurfaceSecondary)
      .sbCornerRadius(.medium)
  }

  private var verifyButton: some View {
    Button {
      Task { await viewModel.verify() }
    } label: {
      Group {
        if viewModel.state == .loading {
          ProgressView()
            .tint(Color.sbTextOnAccent)
        } else {
          Text(Localized.Auth.otpVerify.localizedKey)
        }
      }
      .font(.sbBodySemiboldDefault)
      .foregroundStyle(Color.sbTextOnAccent)
      .frame(maxWidth: .infinity)
      .sbControlHeight(.regular)
      .background(Color.sbAccentPrimary)
      .sbCornerRadius(.default)
    }
    .disabled(viewModel.otpCode.isEmpty)
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
