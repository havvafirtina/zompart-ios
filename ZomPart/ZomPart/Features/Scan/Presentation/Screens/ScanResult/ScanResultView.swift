import SwiftUI
import SBDesignSystem

struct ScanResultView: View {

    let part: ScanPartSummaryDomain
    let onViewOffers: () -> Void

    var body: some View {
        VStack {
            Spacer()

            // Trust signal: prefer the canonical part image from Autodoc/TecDoc when
            // available; fall back to the legacy generic success seal.
            if let urlString = part.displayImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .sbCornerRadius(.default)
                    case .failure:
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.sbStatusSuccess)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.sbStatusSuccess)
            }

            Text(Localized.Scan.resultTitle.localizedKey)
                .font(.sbTitleSemiboldXLarge)
                .foregroundStyle(Color.sbTextPrimary)
                .sbVerticalPadding(.medium)

            VStack(spacing: 4) {
                Text(part.localizedName)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextPrimary)

                Text(part.partNumber)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)

                // Vehicle-OEM origin badge — e.g. "BMW · Bosch" — when both are known.
                if let manufacturer = part.manufacturer, let brand = part.brand {
                    Text("\(manufacturer) · \(brand)")
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbTextSecondary)
                }
            }
            .sbPadding(.large)
            .frame(maxWidth: .infinity)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.default)
            .sbShadow(.soft)

            // Safety-critical warning: AI compatibility check explicitly failed.
            // Shown only when vehicleCompatible == false (nil means "not checked").
            // TODO i18n: extract to Localizable.xcstrings (key suggestion: scan.compatibilityWarning)
            if part.vehicleCompatible == false {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.sbStatusWarning)
                    Text("This part may not fit your vehicle. Double-check the OEM number before purchasing.")
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbTextPrimary)
                }
                .sbPadding(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.sbSurfaceSecondary)
                .sbCornerRadius(.default)
                .sbVerticalPadding(.medium)
            }

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
