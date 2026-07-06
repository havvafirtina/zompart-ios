import Foundation
import SBNetworking
import Testing
@testable import ZomPart

@Suite
struct ScanFeedbackEncodingTests {

    private func encodedBody<T: Endpoint>(_ endpoint: T) throws -> [String: Any] {
        let payload = try #require(endpoint.payload)
        let data = try JSONEncoder().encode(payload)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test func selectPartBodyMatchesContract() throws {
        let endpoint = ScanSelectPartRequest(scanId: "scan-1", partCandidateId: "cand-9").toEndpoint()
        let body = try encodedBody(endpoint)
        #expect(body["scan_id"] as? String == "scan-1")
        #expect(body["action"] as? String == "SELECT_PART")
        #expect(body["selected_part_id"] as? String == "cand-9")
        #expect(body["manual_query"] == nil, "nil optionals must be omitted, not null")
    }

    @Test func manualSearchBodyMatchesContract() throws {
        let endpoint = ScanManualSearchRequest(scanId: "scan-1", query: "HU 719/7x").toEndpoint()
        let body = try encodedBody(endpoint)
        #expect(body["scan_id"] as? String == "scan-1")
        #expect(body["action"] as? String == "MANUAL_SEARCH")
        #expect(body["manual_query"] as? String == "HU 719/7x")
        #expect(body["selected_part_id"] == nil)
    }

    /// The DISAMBIGUATION wire field `part_number` actually carries the
    /// part-candidate UUID; it must land on `ScanAlternativeDomain.id` so the
    /// SELECT_PART chain sends it back as `selected_part_id`.
    @Test func alternativePartNumberDecodesAsCandidateId() throws {
        let json = Data("""
        { "name": "Rear Brake Pad", "part_number": "6f7d1c2e-1111-2222-3333-444455556666", "confidence": 0.55 }
        """.utf8)
        let dto = try JSONDecoder().decode(ScanAlternativeDTO.self, from: json)
        #expect(dto.id == "6f7d1c2e-1111-2222-3333-444455556666")
        #expect(dto.toModel().id == dto.id)
    }
}
