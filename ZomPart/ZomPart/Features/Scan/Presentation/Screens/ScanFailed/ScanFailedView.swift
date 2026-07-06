import SwiftUI
import SBDesignSystem

struct ScanFailedView: View {

    @Bindable var viewModel: ScanFailedViewModel
    let reason: String
    let onRetry: () -> Void
    let onTextSearch: () -> Void
    let onGoHome: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.sbStatusWarning)

            Text(Localized.Scan.failedTitle.localizedKey)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbTextPrimary)
                .sbVerticalPadding(.medium)

            Text(Localized.Scan.failedSubtitle.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            if !reason.isEmpty {
                Text(reason)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextTertiary)
                    .multilineTextAlignment(.center)
                    .sbVerticalPadding(.small)
            }

            manualSearchSection

            Spacer()

            VStack {
                Button {
                    onRetry()
                } label: {
                    Text(Localized.Common.retry.localizedKey)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbTextOnAccent)
                        .frame(maxWidth: .infinity)
                        .sbControlHeight(.regular)
                        .background(Color.sbAccentPrimary)
                        .sbCornerRadius(.default)
                }

                Button {
                    onTextSearch()
                } label: {
                    Text(Localized.Scan.searchByText.localizedKey)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbAccentPrimary)
                        .frame(maxWidth: .infinity)
                        .sbControlHeight(.regular)
                        .background(Color.sbAccentSubtle)
                        .sbCornerRadius(.default)
                }

                Button {
                    onGoHome()
                } label: {
                    Text(Localized.Scan.goHome.localizedKey)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbTextSecondary)
                        .frame(maxWidth: .infinity)
                        .sbControlHeight(.regular)
                }
            }
        }
        .sbPadding(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sbSurfacePrimary)
        .navigationBarBackButtonHidden()
        .disabled(viewModel.state == .loading)
        .overlay {
            if viewModel.state == .loading {
                ProgressView()
            }
        }
    }

    // Backend answers FAILED with next_action MANUAL_SEARCH: resolving a
    // typed part number on the same scan goes straight to offers.
    private var manualSearchSection: some View {
        VStack(alignment: .leading) {
            Text(Localized.Scan.manualSearchTitle.localizedKey)
                .font(.sbBodyRegularSmall)
                .foregroundStyle(Color.sbTextSecondary)

            HStack {
                TextField(
                    Localized.Scan.manualSearchPlaceholder.localized,
                    text: $viewModel.manualQuery
                )
                .font(.sbBodyMediumDefault)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .sbPadding(.medium)
                .background(Color.sbSurfaceSecondary)
                .sbCornerRadius(.medium)

                Button {
                    Task { await viewModel.manualSearch() }
                } label: {
                    Text(Localized.Scan.manualSearchAction.localizedKey)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbAccentPrimary)
                        .sbPadding(.medium)
                        .background(Color.sbAccentSubtle)
                        .sbCornerRadius(.medium)
                }
                .disabled(viewModel.manualQuery.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbStatusError)
            }
        }
        .sbVerticalPadding(.large)
    }
}
