import SwiftUI
import SBDesignSystem

struct OffersListView: View {

    let viewModel: OffersListViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty:
                emptyState

            case .loaded:
                sortPicker
                offersList

            case .error(let message):
                errorState(message)
            }
        }
        .background(Color.sbSurfacePrimary)
        .navigationTitle(Localized.Scan.viewOffers.localized)
        .task {
            if viewModel.state == .idle {
                await viewModel.loadOffers()
            }
        }
        .sheet(item: Binding(
            get: { viewModel.redirectUrl.map { IdentifiableURL(url: $0) } },
            set: { _ in viewModel.dismissSafari() }
        )) { item in
            SafariView(url: item.url)
        }
        .onChange(of: viewModel.externalUrl) { _, newValue in
            guard let url = newValue else { return }
            openURL(url)
            viewModel.dismissExternalUrl()
        }
    }

    // MARK: - Part Header

    @ViewBuilder
    private var partHeader: some View {
        if let part = viewModel.part {
            HStack {
                VStack(alignment: .leading) {
                    Text(part.name)
                        .font(.sbBodySemiboldDefault)
                        .foregroundStyle(Color.sbTextPrimary)

                    Text(part.partNumber)
                        .font(.sbBodyRegularSmall)
                        .foregroundStyle(Color.sbTextSecondary)
                }

                Spacer()
            }
            .sbPadding(.large)
            .background(Color.sbSurfaceSecondary)
            .sbCornerRadius(.default)
        }
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        Picker("", selection: Binding(
            get: { viewModel.selectedSort },
            set: { viewModel.changeSort($0) }
        )) {
            Text(Localized.Offers.recommended.localizedKey)
                .tag(OfferSortDomain.recommended)
            Text(Localized.Offers.cheapest.localizedKey)
                .tag(OfferSortDomain.cheapest)
            Text(Localized.Offers.fastest.localizedKey)
                .tag(OfferSortDomain.fastest)
        }
        .pickerStyle(.segmented)
        .sbHorizontalPadding(.large)
        .sbVerticalPadding(.medium)
    }

    // MARK: - Offers List

    private var offersList: some View {
        List {
            partHeader
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            ForEach(viewModel.offers, id: \.id) { offer in
                OfferCardView(offer: offer) {
                    Task { await viewModel.recordClick(offer: offer) }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Image(systemName: "tag.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbTextTertiary)

            Text(Localized.Offers.empty.localizedKey)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            // Offers are produced asynchronously by the backend after a
            // scan — an empty first response is normal, so let the user ask
            // again instead of dead-ending (the cached VM never re-queries).
            Button(Localized.Common.retry.localizedKey) {
                Task { await viewModel.loadOffers() }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbAccentPrimary)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.sbTextTertiary)

            Text(message)
                .font(.sbBodyRegularDefault)
                .foregroundStyle(Color.sbTextSecondary)
                .multilineTextAlignment(.center)

            Button(Localized.Common.retry.localized) {
                Task { await viewModel.loadOffers() }
            }
            .font(.sbBodySemiboldDefault)
            .foregroundStyle(Color.sbAccentPrimary)
        }
        .sbPadding(.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct IdentifiableURL: Identifiable {
    // Identity derives from the URL itself: a fresh UUID per body
    // evaluation would make SwiftUI treat every render as a new sheet item
    // and re-present the sheet.
    let url: URL
    var id: String { url.absoluteString }
}
