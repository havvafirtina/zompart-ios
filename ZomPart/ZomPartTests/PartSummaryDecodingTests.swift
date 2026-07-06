import Foundation
import Testing
@testable import ZomPart

/// Guards the manual `CodingKeys` of the four part-summary DTO copies
/// (Scan / Offer / History / Catalog). The decoder has no snake_case
/// strategy, so a typo in any key silently drops the field — these fixtures
/// are the only automated net.
@Suite
struct PartSummaryDecodingTests {

    /// Full prod-shaped payload including the 2026-07 TecDoc enrichment.
    private static let fullJSON = Data("""
    {
      "id": "cand-1",
      "name": "Brake Caliper",
      "name_tr": null,
      "name_sv": "Bromsok",
      "part_number": "38217",
      "thumbnail_url": null,
      "oem_number": "1682499",
      "mpn": "38217",
      "ean": "4006633314657",
      "brand": "TRW",
      "manufacturer": "FORD",
      "cross_references": ["1682499", "2013804"],
      "category_tecdoc": "Brake Caliper",
      "vehicle_compatible": true,
      "image_url": "https://cdn.example.com/38217.webp",
      "confidence_score": 0.91,
      "generic_article_id": 82,
      "article_criteria": [
        { "criteria_id": 100, "label": "Fitting Position", "value": "Front Axle", "unit": null },
        { "criteria_id": null, "label": "Diameter", "value": "280", "unit": "mm" }
      ],
      "fitment_confirmed": true
    }
    """.utf8)

    /// Pre-cutover row: none of the new fields present. Must still decode
    /// (History shows old scans) and default cleanly.
    private static let legacyJSON = Data("""
    {
      "id": "cand-2",
      "name": "Oil Filter",
      "part_number": "HU 719/7x"
    }
    """.utf8)

    // MARK: - Scan copy

    @Test func scanPartSummaryDecodesEnrichment() throws {
        let dto = try JSONDecoder().decode(ScanPartSummaryDTO.self, from: Self.fullJSON)
        let model = dto.toModel()
        #expect(model.genericArticleId == 82)
        #expect(model.fitmentConfirmed)
        #expect(model.articleCriteria.count == 2)
        #expect(model.articleCriteria[0].criteriaId == 100)
        #expect(model.articleCriteria[0].value == "Front Axle")
        #expect(model.articleCriteria[1].criteriaId == nil)
        #expect(model.articleCriteria[1].unit == "mm")
        #expect(model.articleCriteria[1].displayText == "Diameter: 280 mm")
    }

    @Test func scanPartSummaryDefaultsWithoutEnrichment() throws {
        let dto = try JSONDecoder().decode(ScanPartSummaryDTO.self, from: Self.legacyJSON)
        let model = dto.toModel()
        #expect(model.genericArticleId == nil)
        #expect(!model.fitmentConfirmed)
        #expect(model.articleCriteria.isEmpty)
    }

    // MARK: - Offer copy

    @Test func offerPartSummaryDecodesEnrichment() throws {
        let dto = try JSONDecoder().decode(OfferPartSummaryDTO.self, from: Self.fullJSON)
        let model = dto.toModel()
        #expect(model.genericArticleId == 82)
        #expect(model.fitmentConfirmed)
        #expect(model.articleCriteria.count == 2)
    }

    @Test func offerPartSummaryDefaultsWithoutEnrichment() throws {
        let model = try JSONDecoder().decode(OfferPartSummaryDTO.self, from: Self.legacyJSON).toModel()
        #expect(model.genericArticleId == nil)
        #expect(!model.fitmentConfirmed)
        #expect(model.articleCriteria.isEmpty)
    }

    // MARK: - History copy

    @Test func historyPartSummaryDecodesEnrichment() throws {
        let model = try JSONDecoder().decode(HistoryPartSummaryDTO.self, from: Self.fullJSON).toModel()
        #expect(model.genericArticleId == 82)
        #expect(model.fitmentConfirmed)
        #expect(model.articleCriteria.count == 2)
    }

    @Test func historyPartSummaryDefaultsWithoutEnrichment() throws {
        let model = try JSONDecoder().decode(HistoryPartSummaryDTO.self, from: Self.legacyJSON).toModel()
        #expect(model.genericArticleId == nil)
        #expect(!model.fitmentConfirmed)
        #expect(model.articleCriteria.isEmpty)
    }

    // MARK: - Catalog copy

    @Test func catalogPartSummaryDecodesEnrichment() throws {
        let model = try JSONDecoder().decode(CatalogPartSummaryDTO.self, from: Self.fullJSON).toModel()
        #expect(model.genericArticleId == 82)
        #expect(model.fitmentConfirmed)
        #expect(model.articleCriteria.count == 2)
        #expect(model.vehicleCompatible == true)
    }

    @Test func catalogPartSummaryDefaultsWithoutEnrichment() throws {
        let model = try JSONDecoder().decode(CatalogPartSummaryDTO.self, from: Self.legacyJSON).toModel()
        #expect(model.genericArticleId == nil)
        #expect(!model.fitmentConfirmed)
        #expect(model.articleCriteria.isEmpty)
    }
}
