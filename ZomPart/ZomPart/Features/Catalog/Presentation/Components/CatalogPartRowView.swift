import SwiftUI
import SBDesignSystem

struct CatalogPartRowView: View {

    let part: CatalogPartSummaryDomain

    var body: some View {
        HStack(alignment: .top) {
            thumbnail

            VStack(alignment: .leading, spacing: 2) {
                Text(part.localizedName)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextPrimary)

                Text(part.partNumber)
                    .font(.sbBodyRegularSmall)
                    .foregroundStyle(Color.sbTextSecondary)

                if let brand = part.brand {
                    Text(brand)
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(Color.sbTextTertiary)
                }

                if part.vehicleCompatible == true {
                    Label {
                        Text(Localized.Catalog.fits.localizedKey)
                            .font(.sbBodyRegularXSmall)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.sbBodyRegularXSmall)
                    }
                    .foregroundStyle(Color.sbStatusSuccess)
                }
            }

            Spacer()
        }
        .sbPadding(.large)
        .background(Color.sbSurfaceSecondary)
        .sbCornerRadius(.default)
        .sbShadow(.soft)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let urlString = part.displayImageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.sbSurfaceTertiary
            }
            .frame(width: 48, height: 48)
            .sbCornerRadius(.small)
        } else {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundStyle(Color.sbTextTertiary)
                .frame(width: 48, height: 48)
                .background(Color.sbSurfaceTertiary)
                .sbCornerRadius(.small)
        }
    }
}
