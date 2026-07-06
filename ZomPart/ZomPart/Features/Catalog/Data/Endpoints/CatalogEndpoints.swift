import Foundation
import SBNetworking

// ─────────────────────────────────────────
// MARK: - vehicle-parts (category tree)
// ─────────────────────────────────────────

struct CatalogCategoriesRequest: RequestProtocol {
    typealias EndpointType = VehiclePartsCategoriesEndpoint
    let vehicleId: String
    func toEndpoint() -> VehiclePartsCategoriesEndpoint {
        VehiclePartsCategoriesEndpoint(vehicleId: vehicleId)
    }
}

struct VehiclePartsCategoriesEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<CatalogCategoriesDataDTO>
    let vehicleId: String
    var path: String { "/functions/v1/vehicle-parts" }
    var method: HTTPMethod { .post }
    var payload: Encodable? { VehiclePartsBody(vehicleId: vehicleId, categoryId: nil) }
    // Live TecDoc proxy (no cache) — the full tree call can be slow.
    var timeoutInterval: TimeInterval { 60 }
}

// ─────────────────────────────────────────
// MARK: - vehicle-parts (articles in a node)
// ─────────────────────────────────────────

struct CatalogArticlesRequest: RequestProtocol {
    typealias EndpointType = VehiclePartsArticlesEndpoint
    let vehicleId: String
    let categoryId: Int
    func toEndpoint() -> VehiclePartsArticlesEndpoint {
        VehiclePartsArticlesEndpoint(vehicleId: vehicleId, categoryId: categoryId)
    }
}

struct VehiclePartsArticlesEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<CatalogArticlesDataDTO>
    let vehicleId: String
    let categoryId: Int
    var path: String { "/functions/v1/vehicle-parts" }
    var method: HTTPMethod { .post }
    var payload: Encodable? { VehiclePartsBody(vehicleId: vehicleId, categoryId: categoryId) }
    var timeoutInterval: TimeInterval { 60 }
}

private struct VehiclePartsBody: Encodable {
    let vehicleId: String
    // nil (omitted) → assembly-group tree; set → articles of that node.
    let categoryId: Int?
    private enum CodingKeys: String, CodingKey {
        case vehicleId  = "vehicle_id"
        case categoryId = "category_id"
    }
}

// ─────────────────────────────────────────
// MARK: - parts-search
// ─────────────────────────────────────────

struct PartsSearchRequest: RequestProtocol {
    typealias EndpointType = PartsSearchEndpoint
    let articleNumber: String
    let vehicleId: String?
    func toEndpoint() -> PartsSearchEndpoint {
        PartsSearchEndpoint(articleNumber: articleNumber, vehicleId: vehicleId)
    }
}

struct PartsSearchEndpoint: Endpoint {
    typealias ResponseType = APIEnvelope<PartsSearchDataDTO>
    let articleNumber: String
    let vehicleId: String?
    var path: String { "/functions/v1/parts-search" }
    var method: HTTPMethod { .post }
    var payload: Encodable? {
        // country_code omitted → backend defaults to SE (the licensed market
        // matching the vehicle flow). TecDoc text language follows the
        // request's Accept-Language (licensed set da/fi/no/sv).
        PartsSearchBody(articleNumber: articleNumber, vehicleId: vehicleId)
    }
    var timeoutInterval: TimeInterval { 60 }
}

private struct PartsSearchBody: Encodable {
    let articleNumber: String
    let vehicleId: String?
    private enum CodingKeys: String, CodingKey {
        case articleNumber = "article_number"
        case vehicleId     = "vehicle_id"
    }
}
