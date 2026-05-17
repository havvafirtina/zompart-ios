import Foundation

@MainActor
@Observable
final class OffersListViewModel {

    private(set) var state: ViewState<OfferListDomain> = .idle
    private(set) var offers: [OfferDomain] = []
    private(set) var part: OfferPartSummaryDomain?
    var selectedSort: OfferSortDomain = .recommended
    private(set) var redirectUrl: URL?

    private let scanId: String
    private let offerRepository: OfferRepositoryProtocol

    init(scanId: String, offerRepository: OfferRepositoryProtocol) {
        self.scanId = scanId
        self.offerRepository = offerRepository
    }

    func loadOffers() async {
        let previousOffers = offers
        state = .loading
        do {
            let result = try await offerRepository.listOffers(scanId: scanId, sort: selectedSort)
            part = result.part
            offers = result.offers
            state = result.offers.isEmpty ? .empty : .loaded(result)
        } catch is CancellationError {
            offers = previousOffers
            if !previousOffers.isEmpty {
                state = .loaded(OfferListDomain(scanId: scanId, part: part, offers: previousOffers, sortApplied: selectedSort, totalCount: previousOffers.count))
            } else {
                state = .idle
            }
        } catch {
            state = .error(Localized.Error.network.localized)
        }
    }

    func changeSort(_ sort: OfferSortDomain) async {
        guard sort != selectedSort else { return }
        selectedSort = sort
        await loadOffers()
    }

    func recordClick(offer: OfferDomain) async {
        do {
            let result = try await offerRepository.recordClick(offerId: offer.id, scanId: scanId)
            if let url = URL(string: result.redirectUrl) {
                redirectUrl = url
            }
        } catch {
            if let url = URL(string: offer.url) {
                redirectUrl = url
            }
        }
    }

    func dismissSafari() {
        redirectUrl = nil
    }
}
