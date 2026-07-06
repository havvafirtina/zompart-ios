import Foundation

@MainActor
@Observable
final class PartsSearchViewModel {

    private(set) var state: ViewState<CatalogSearchPageDomain> = .idle
    var query = ""

    private let vehicleId: String?
    private let catalogRepository: CatalogRepositoryProtocol

    init(vehicleId: String?, catalogRepository: CatalogRepositoryProtocol) {
        self.vehicleId = vehicleId
        self.catalogRepository = catalogRepository
    }

    /// Search on explicit submit only — every call is a live TecDoc request
    /// behind a no-cache proxy, so no per-keystroke querying.
    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state = .loading
        do {
            let page = try await catalogRepository.search(articleNumber: trimmed, vehicleId: vehicleId)
            state = page.articles.isEmpty ? .empty : .loaded(page)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch let error as CatalogError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }
}
