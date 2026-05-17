import SwiftUI
import SBDesignSystem

struct OfferCardView: View {

    let offer: OfferDomain
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    vendorInfo
                    Spacer()
                    priceLabel
                }

                HStack {
                    if let deliveryLabel = offer.deliveryLabel {
                        Label(deliveryLabel, systemImage: "shippingbox.fill")
                            .font(.sbBodyRegularSmall)
                            .foregroundStyle(Color.sbTextSecondary)
                    }

                    Spacer()

                    if let rating = offer.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.sbBodyRegularXSmall)
                                .foregroundStyle(Color.sbStatusWarning)
                            Text(String(format: "%.1f", rating))
                                .font(.sbBodyRegularSmall)
                                .foregroundStyle(Color.sbTextSecondary)
                            if let count = offer.ratingCount {
                                Text("(\(count))")
                                    .font(.sbBodyRegularXSmall)
                                    .foregroundStyle(Color.sbTextTertiary)
                            }
                        }
                    }
                }

                if offer.isSponsored {
                    Text(Localized.Offers.sponsored.localizedKey)
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(Color.sbTextTertiary)
                }
            }
            .sbPadding(.large)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.default)
            .sbShadow(.soft)
        }
        .buttonStyle(.plain)
        .opacity(offer.isAvailable ? 1.0 : 0.4)
    }

    private var vendorInfo: some View {
        HStack {
            if let logoUrl = offer.vendorLogoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.sbSurfaceTertiary
                }
                .frame(width: 36, height: 36)
                .sbCornerRadius(.small)
            }

            VStack(alignment: .leading) {
                Text(offer.vendorName)
                    .font(.sbBodySemiboldDefault)
                    .foregroundStyle(Color.sbTextPrimary)

                if let stockLabel = offer.stockLabel {
                    Text(stockLabel)
                        .font(.sbBodyRegularXSmall)
                        .foregroundStyle(
                            offer.isAvailable ? Color.sbStatusSuccess : Color.sbStatusError
                        )
                }
            }
        }
    }

    private var priceLabel: some View {
        VStack(alignment: .trailing) {
            Text(offer.formattedPrice)
                .font(.sbTitleSemiboldLarge)
                .foregroundStyle(Color.sbAccentPrimary)

            Text(offer.currency)
                .font(.sbBodyRegularXSmall)
                .foregroundStyle(Color.sbTextTertiary)
        }
    }
}
