import SwiftUI
import SBDesignSystem

struct ScanFailedView: View {

    let reason: String
    let onRetry: () -> Void
    let onTextSearch: () -> Void

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
            }
        }
        .sbPadding(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sbSurfacePrimary)
        .navigationBarBackButtonHidden()
    }
}
