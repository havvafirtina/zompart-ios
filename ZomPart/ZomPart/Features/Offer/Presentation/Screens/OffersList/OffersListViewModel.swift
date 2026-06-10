import Foundation

@MainActor
@Observable
final class OffersListViewModel {

    private(set) var state: ViewState<OfferListDomain> = .idle
    private(set) var offers: [OfferDomain] = []
    private(set) var part: OfferPartSummaryDomain?
    var selectedSort: OfferSortDomain = .recommended
    /// http(s) destination shown in the in-app Safari sheet.
    private(set) var redirectUrl: URL?
    /// Non-web destination (tel:, mailto:, store deeplink) — the view hands
    /// it to the system, because SFSafariViewController crashes on those.
    private(set) var externalUrl: URL?

    private var allOffers: [OfferDomain] = []
    private let scanId: String
    private let offerRepository: OfferRepositoryProtocol

    init(scanId: String, offerRepository: OfferRepositoryProtocol) {
        self.scanId = scanId
        self.offerRepository = offerRepository
    }

    func loadOffers() async {
        let previousOffers = allOffers
        state = .loading
        do {
            let result = try await offerRepository.listOffers(scanId: scanId, sort: .recommended)
            part = result.part
            allOffers = result.offers
            applySort()
        } catch is CancellationError {
            allOffers = previousOffers
            if !previousOffers.isEmpty {
                applySort()
            } else {
                state = .idle
            }
        } catch let error as OfferError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }

    func changeSort(_ sort: OfferSortDomain) {
        guard sort != selectedSort else { return }
        selectedSort = sort
        applySort()
    }

    private func applySort() {
        switch selectedSort {
        case .recommended:
            offers = allOffers
        case .cheapest:
            // Prices in different currencies are not comparable without FX
            // data (100 SEK is not cheaper than 90 EUR) — sort within each
            // currency group, dominant currency group first.
            let counts = Dictionary(grouping: allOffers, by: \.currency).mapValues(\.count)
            offers = allOffers.sorted {
                if $0.currency == $1.currency { return $0.price < $1.price }
                let lhs = counts[$0.currency] ?? 0
                let rhs = counts[$1.currency] ?? 0
                if lhs != rhs { return lhs > rhs }
                return $0.currency < $1.currency
            }
        case .fastest:
            offers = allOffers.sorted {
                ($0.deliveryDays ?? Int.max) < ($1.deliveryDays ?? Int.max)
            }
        }
        state = offers.isEmpty ? .empty : .loaded(
            OfferListDomain(scanId: scanId, part: part, offers: offers, sortApplied: selectedSort, totalCount: offers.count)
        )
    }

    func recordClick(offer: OfferDomain) async {
        do {
            let result = try await offerRepository.recordClick(offerId: offer.id, scanId: scanId)
            route(URL(string: result.redirectUrl))
        } catch {
            route(URL(string: offer.url))
        }
    }

    private func route(_ url: URL?) {
        guard let url else { return }
        if url.scheme == "http" || url.scheme == "https" {
            redirectUrl = url
        } else {
            externalUrl = url
        }
    }

    func dismissSafari() {
        redirectUrl = nil
    }

    func dismissExternalUrl() {
        externalUrl = nil
    }
}
