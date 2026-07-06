import Foundation

@MainActor
@Observable
final class CatalogBrowseViewModel {

    private(set) var state: ViewState<CatalogCategoryPageDomain> = .idle

    let vehicleId: String
    private let catalogRepository: CatalogRepositoryProtocol

    init(vehicleId: String, catalogRepository: CatalogRepositoryProtocol) {
        self.vehicleId = vehicleId
        self.catalogRepository = catalogRepository
    }

    /// Loads the full flat assembly-group tree once; drill-down is client-side.
    /// The backend proxies TecDoc live (no cache), so no auto-refresh.
    func load() async {
        if case .loaded = state { return }
        state = .loading
        do {
            let page = try await catalogRepository.categories(vehicleId: vehicleId)
            state = page.categories.isEmpty ? .empty : .loaded(page)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch let error as CatalogError {
            state = .error(error.localizedMessage)
        } catch {
            state = .error(Localized.Error.unknown.localized)
        }
    }
}
