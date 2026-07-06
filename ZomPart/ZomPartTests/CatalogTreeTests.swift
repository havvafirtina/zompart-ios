import Foundation
import Testing
@testable import ZomPart

@Suite
struct CatalogTreeTests {

    private static let page = CatalogCategoryPageDomain(
        carId: 141039,
        categories: [
            CatalogCategoryDomain(id: 1, name: "Braking System", parentId: nil, articleCount: 42),
            CatalogCategoryDomain(id: 2, name: "Engine", parentId: nil, articleCount: 130),
            CatalogCategoryDomain(id: 11, name: "Brake Caliper", parentId: 1, articleCount: 8),
            CatalogCategoryDomain(id: 12, name: "Brake Disc", parentId: 1, articleCount: 14)
        ],
        totalCount: 4
    )

    @Test func topLevelIsParentNil() {
        let top = Self.page.children(of: nil)
        #expect(top.map(\.id) == [1, 2])
    }

    @Test func childrenResolveByParentId() {
        let children = Self.page.children(of: 1)
        #expect(children.map(\.id) == [11, 12])
    }

    @Test func leafDetection() {
        #expect(!Self.page.isLeaf(Self.page.categories[0]))
        #expect(Self.page.isLeaf(Self.page.categories[2]))
    }

    /// Wire rows with a null id cannot be drilled into — the DTO mapping drops them.
    @Test func nullIdCategoriesAreDropped() throws {
        let json = Data("""
        {
          "vehicle_id": "veh-1",
          "car_id": 141039,
          "categories": [
            { "id": 1, "name": "Braking System", "parent_id": null, "article_count": 42 },
            { "id": null, "name": "Ghost", "parent_id": null, "article_count": null }
          ],
          "total_count": 2
        }
        """.utf8)
        let page = try JSONDecoder().decode(CatalogCategoriesDataDTO.self, from: json).toModel()
        #expect(page.categories.count == 1)
        #expect(page.categories[0].id == 1)
    }
}
