import Foundation
import Testing
@testable import ZomPart

@Suite
struct OfferDecodingTests {

    private static func offerJSON(extraFields: String = "") -> Data {
        Data("""
        {
          "id": "offer-1",
          "vendor_name": "eBay",
          "vendor_slug": "ebay",
          "vendor_logo_url": null,
          "price": 142.0,
          "formatted_price": "142,00 €",
          "currency": "EUR",
          "delivery_days": 5,
          "delivery_label": "3-5 business days",
          "url": "https://www.ebay.de/itm/1",
          "is_sponsored": false,
          "is_available": true,
          "stock_label": null,
          "rating": null,
          "rating_count": null,
          "source_provider": "ebay-browse",
          "sku": "1234",
          "gtin": null,
          "merchant_id": "seller-x",
          "expires_at": null,
          "affiliate_metadata": null
          \(extraFields)
        }
        """.utf8)
    }

    @Test func isAffiliateTrueDecodes() throws {
        let dto = try JSONDecoder().decode(
            OfferItemDTO.self,
            from: Self.offerJSON(extraFields: ", \"is_affiliate\": true")
        )
        let model = dto.toModel()
        #expect(model.isAffiliate)
        #expect(!model.isSponsored, "is_affiliate must stay a separate concept from is_sponsored")
    }

    /// Offers stored before the 2026-07-06 backend deploy have no
    /// `is_affiliate` — the disclosure flag must default to false, never crash.
    @Test func isAffiliateDefaultsFalseWhenAbsent() throws {
        let dto = try JSONDecoder().decode(OfferItemDTO.self, from: Self.offerJSON())
        #expect(dto.toModel().isAffiliate == false)
    }

    /// `affiliate_metadata.ebay_title` (2026-07-07 backend) carries the
    /// marketplace listing title — rendered as the offer-card subtitle.
    /// Older payloads without it must keep decoding (nil title).
    @Test func ebayTitleDecodesFromAffiliateMetadata() throws {
        // The base fixture carries `"affiliate_metadata": null`; swap in an
        // object variant with the listing title.
        let json = String(data: Self.offerJSON(), encoding: .utf8)!
            .replacingOccurrences(
                of: "\"affiliate_metadata\": null",
                with: """
                "affiliate_metadata": { "ebay_item_id": "v1|1|0", "ebay_marketplace": "EBAY_DE", "ebay_title": "Anlasser Starter 2,2 KW für KIA Sorento I JC 2.5 CRDi" }
                """
            )
        let dto = try JSONDecoder().decode(OfferItemDTO.self, from: Data(json.utf8))
        #expect(dto.toModel().affiliateMetadata?.ebayTitle == "Anlasser Starter 2,2 KW für KIA Sorento I JC 2.5 CRDi")
    }

    @Test func ebayTitleNilWhenMetadataOmitsIt() throws {
        let json = String(data: Self.offerJSON(), encoding: .utf8)!
            .replacingOccurrences(
                of: "\"affiliate_metadata\": null",
                with: "\"affiliate_metadata\": { \"ebay_item_id\": \"v1|1|0\" }"
            )
        let dto = try JSONDecoder().decode(OfferItemDTO.self, from: Data(json.utf8))
        #expect(dto.toModel().affiliateMetadata?.ebayTitle == nil)
    }
}
