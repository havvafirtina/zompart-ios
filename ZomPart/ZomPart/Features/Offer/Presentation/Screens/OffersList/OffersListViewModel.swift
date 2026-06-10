import Foundation

@MainActor
@Observable
final class OffersListViewModel {

    private(set) var state: ViewState<OfferListDomain> = .idle
    private(set) var offers: [OfferDomain] = []
    private(set) var part: OfferPartSummaryDomain?
    var selectedSort: OfferSortDomain = .recommended
    private(set) var redirectUrl: URL?

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
            offers = allOffers.sorted { $0.price < $1.price }
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
