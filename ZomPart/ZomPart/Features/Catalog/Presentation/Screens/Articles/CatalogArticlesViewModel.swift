import Foundation

@MainActor
@Observable
final class CatalogArticlesViewModel {

    private(set) var state: ViewState<CatalogArticlesPageDomain> = .idle

    let category: CatalogCategoryDomain
    private let vehicleId: String
    private let catalogRepository: CatalogRepositoryProtocol

    init(
        vehicleId: String,
        category: CatalogCategoryDomain,
        catalogRepository: CatalogRepositoryProtocol
    ) {
        self.vehicleId = vehicleId
        self.category = category
        self.catalogRepository = catalogRepository
    }

    func load() async {
        if case .loaded = state { return }
        state = .loading
        do {
            let page = try await catalogRepository.articles(vehicleId: vehicleId, categoryId: category.id)
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
