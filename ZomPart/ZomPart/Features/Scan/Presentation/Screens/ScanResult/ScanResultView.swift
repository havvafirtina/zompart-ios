import SwiftUI
import SBDesignSystem

struct ScanResultView: View {

    let partName: String
    let partNumber: String
    let onViewOffers: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.sbStatusSuccess)

            Text(Localized.Scan.resultTitle.localizedKey)
                .font(.sbTitleSemiboldXLarge)
                .foregroundStyle(Color.sbTextPrimary)
                .sbVerticalPadding(.medium)

            VStack {
                Text(partName)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextPrimary)

                Text(partNumber)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)
            }
            .sbPadding(.large)
            .frame(maxWidth: .infinity)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.default)
            .sbShadow(.soft)

            Spacer()

            Button {
                onViewOffers()
            } label: {
                Text(Localized.Scan.viewOffers.localizedKey)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextOnAccent)
                    .frame(maxWidth: .infinity)
                    .sbControlHeight(.regular)
                    .background(Color.sbAccentPrimary)
                    .sbCornerRadius(.default)
            }
        }
        .sbPadding(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sbSurfacePrimary)
        .navigationBarBackButtonHidden()
    }
}
