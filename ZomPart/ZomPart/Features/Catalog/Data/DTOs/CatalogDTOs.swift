import Foundation
import SBNetworking

// MARK: - Shared article shapes

struct CatalogArticleCriterionDTO: Decodable, Sendable {
    /// TecDoc criterion id — nullable on the wire despite the contract table.
    let criteriaId: Int?
    let label: String
    /// Always a string on the wire (`formattedValue ?? rawValue`).
    let value: String
    let unit: String?

    private enum CodingKeys: String, CodingKey {
        case criteriaId = "criteria_id"
        case label, value, unit
    }

    func toModel() -> CatalogArticleCriterionDomain {
        CatalogArticleCriterionDomain(criteriaId: criteriaId, label: label, value: value, unit: unit)
    }
}

/// SelectedPartSummary shape as returned by vehicle-parts / parts-search —
/// identical to the scan flow's part objects. Kept as an independent copy;
/// feature isolation forbids cross-feature imports.
struct CatalogPartSummaryDTO: Decodable, Sendable {
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
    let vehicleCompatible: Bool?
    let imageUrl: String?
    let confidenceScore: Double?
    let genericArticleId: Int?
    let articleCriteria: [CatalogArticleCriterionDTO]?
    let fitmentConfirmed: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, name, brand, manufacturer, mpn, ean
        case nameTr = "name_tr"
        case nameSv = "name_sv"
        case partNumber = "part_number"
        case thumbnailUrl = "thumbnail_url"
        case oemNumber = "oem_number"
        case crossReferences = "cross_references"
        case categoryTecdoc = "category_tecdoc"
        case vehicleCompatible = "vehicle_compatible"
        case imageUrl = "image_url"
        case confidenceScore = "confidence_score"
        case genericArticleId = "generic_article_id"
        case articleCriteria = "article_criteria"
        case fitmentConfirmed = "fitment_confirmed"
    }

    func toModel() -> CatalogPartSummaryDomain {
        CatalogPartSummaryDomain(
            id: id,
            name: name,
            nameTr: nameTr,
            nameSv: nameSv,
            partNumber: partNumber,
            thumbnailUrl: thumbnailUrl,
            oemNumber: oemNumber,
            mpn: mpn,
            ean: ean,
            brand: brand,
            manufacturer: manufacturer,
            crossReferences: crossReferences,
            categoryTecdoc: categoryTecdoc,
            vehicleCompatible: vehicleCompatible,
            imageUrl: imageUrl,
            confidenceScore: confidenceScore,
            genericArticleId: genericArticleId,
            articleCriteria: (articleCriteria ?? []).map { $0.toModel() },
            fitmentConfirmed: fitmentConfirmed ?? false
        )
    }
}

// MARK: - vehicle-parts (category tree)

struct CatalogCategoryDTO: Decodable, Sendable {
    /// Node id can be null on the wire — such rows are dropped in `toModel()`
    /// (they cannot be drilled into).
    let id: Int?
    let name: String
    let parentId: Int?
    let articleCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name
        case parentId = "parent_id"
        case articleCount = "article_count"
    }
}

struct CatalogCategoriesDataDTO: ResponseProtocol {
    typealias ModelType = CatalogCategoryPageDomain

    let vehicleId: String
    let carId: Int?
    let categories: [CatalogCategoryDTO]
    let totalCount: Int

    private enum CodingKeys: String, CodingKey {
        case vehicleId  = "vehicle_id"
        case carId      = "car_id"
        case categories
        case totalCount = "total_count"
    }

    func toModel() -> CatalogCategoryPageDomain {
        let mapped = categories.compactMap { dto -> CatalogCategoryDomain? in
            guard let id = dto.id else { return nil }
            return CatalogCategoryDomain(
                id: id,
                name: dto.name,
                parentId: dto.parentId,
                articleCount: dto.articleCount
            )
        }
        return CatalogCategoryPageDomain(carId: carId, categories: mapped, totalCount: totalCount)
    }
}

// MARK: - vehicle-parts (articles in a node)

struct CatalogArticlesDataDTO: ResponseProtocol {
    typealias ModelType = CatalogArticlesPageDomain

    let vehicleId: String
    let carId: Int?
    let categoryId: Int?
    let articles: [CatalogPartSummaryDTO]
    let totalCount: Int

    private enum CodingKeys: String, CodingKey {
        case vehicleId  = "vehicle_id"
        case carId      = "car_id"
        case categoryId = "category_id"
        case articles
        case totalCount = "total_count"
    }

    func toModel() -> CatalogArticlesPageDomain {
        CatalogArticlesPageDomain(
            carId: carId,
            categoryId: categoryId,
            articles: articles.map { $0.toModel() },
            totalCount: totalCount
        )
    }
}

// MARK: - parts-search

struct PartsSearchDataDTO: ResponseProtocol {
    typealias ModelType = CatalogSearchPageDomain

    let query: String
    let countryCode: String
    let articles: [CatalogPartSummaryDTO]
    let totalCount: Int

    private enum CodingKeys: String, CodingKey {
        case query
        case countryCode = "country_code"
        case articles
        case totalCount  = "total_count"
    }

    func toModel() -> CatalogSearchPageDomain {
        CatalogSearchPageDomain(
            query: query,
            countryCode: countryCode,
            articles: articles.map { $0.toModel() },
            totalCount: totalCount
        )
    }
}
