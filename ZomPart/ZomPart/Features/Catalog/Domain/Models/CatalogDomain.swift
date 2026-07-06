import Foundation

/// Assembly-group node of the TecDoc catalog tree. The backend returns the
/// tree as a FLAT list with `parent_id` links — nesting happens client-side
/// (`CatalogCategoryPageDomain.children(of:)`).
struct CatalogCategoryDomain: Equatable, Hashable, Sendable, Identifiable {
    let id: Int
    let name: String
    let parentId: Int?
    let articleCount: Int?
}

/// One full assembly-group tree response for a vehicle.
struct CatalogCategoryPageDomain: Equatable, Sendable {
    let carId: Int?
    let categories: [CatalogCategoryDomain]
    let totalCount: Int

    /// Direct children of a node; pass `nil` for the top level.
    func children(of parentId: Int?) -> [CatalogCategoryDomain] {
        categories.filter { $0.parentId == parentId }
    }

    func isLeaf(_ category: CatalogCategoryDomain) -> Bool {
        children(of: category.id).isEmpty
    }
}

/// TecDoc criterion of an article (e.g. fitting position, diameter).
/// Mirrors the Scan/Offer/History criterion types — no cross-feature imports.
struct CatalogArticleCriterionDomain: Equatable, Hashable, Sendable {
    let criteriaId: Int?
    let label: String
    let value: String
    let unit: String?
}

/// Catalog article in the shared SelectedPartSummary shape.
/// Defined independently — Catalog must not import Scan/Offer/History.
/// Mirrors `ScanPartSummaryDomain`; keep the copies in sync when Layer 1 evolves.
struct CatalogPartSummaryDomain: Equatable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let nameTr: String?
    let nameSv: String?
    let partNumber: String
    let thumbnailUrl: String?
    let oemNumber: String?
    let mpn: String?
    let ean: String?
    let brand: String?
    let manufacturer: String?
    let crossReferences: [String]?
    let categoryTecdoc: String?
    /// True when the article's compatible cars include the vehicle's carId;
    /// nil when no vehicle context was sent.
    let vehicleCompatible: Bool?
    let imageUrl: String?
    /// Always nil for catalog results (not an AI-scored match).
    let confidenceScore: Double?
    let genericArticleId: Int?
    let articleCriteria: [CatalogArticleCriterionDomain]
    let fitmentConfirmed: Bool

    var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier
        switch lang {
        case "tr": return nameTr ?? name
        case "sv": return nameSv ?? name
        default: return name
        }
    }

    var displayImageUrl: String? {
        imageUrl ?? thumbnailUrl
    }
}

/// Articles inside one assembly-group node.
struct CatalogArticlesPageDomain: Equatable, Sendable {
    let carId: Int?
    let categoryId: Int?
    let articles: [CatalogPartSummaryDomain]
    let totalCount: Int
}

/// Result of a part/OE-number search.
struct CatalogSearchPageDomain: Equatable, Sendable {
    let query: String
    let countryCode: String
    let articles: [CatalogPartSummaryDomain]
    let totalCount: Int
}

/// Feature-specific error type for the Catalog module.
/// `HTTPClientError` is never exposed beyond the repository layer.
enum CatalogError: Error, Equatable {
    case vehicleNotFound
    case countryNotSupported
    /// Vehicle has no carId, TecDoc returned no usable data, or the TecDoc
    /// proxy is down (CATALOG_LOOKUP_FAILED / TECDOC_LOOKUP_FAILED / 5xx).
    case catalogUnavailable
    case tokenExpired
    /// `retryAfter` = seconds until the window resets (backend `meta.retry_after`).
    case rateLimitExceeded(retryAfter: Int?)
    case network
    case emptyResponse
    case unknown
}
