import Foundation

/// Domain interface for TecDoc catalog browsing (vehicle-parts) and
/// part-number search (parts-search). Implemented by `CatalogRepository`.
///
/// The backend is a strict no-cache proxy — every call is a live TecDoc
/// request, so callers must not poll or auto-refresh.
protocol CatalogRepositoryProtocol: Sendable {

    /// Assembly-group (category) tree for a garage vehicle. The vehicle must
    /// have a `tecdoc_ktype` (plate-resolved) or the backend answers
    /// CATALOG_LOOKUP_FAILED.
    func categories(vehicleId: String) async throws -> CatalogCategoryPageDomain

    /// Articles inside one assembly-group node.
    func articles(vehicleId: String, categoryId: Int) async throws -> CatalogArticlesPageDomain

    /// Search articles by part/OE number. Passing a `vehicleId` adds
    /// compatibility info (`vehicle_compatible`) to the results.
    func search(articleNumber: String, vehicleId: String?) async throws -> CatalogSearchPageDomain
}
