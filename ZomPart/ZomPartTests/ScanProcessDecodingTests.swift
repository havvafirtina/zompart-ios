import Foundation
import Testing
@testable import ZomPart

@Suite
struct ScanProcessDecodingTests {

    /// Trimmed real prod payload (device UAT, 2026-07-07): a conventional
    /// starter photographed against a PHEV — the backend answers with a
    /// VEHICLE_MISMATCH disambiguation and a compatibility-flagged candidate.
    @Test func vehicleMismatchPayloadDecodes() throws {
        let json = Data("""
        {
          "scan_id": "472a3bac-6d6c-43c0-932b-548b886cb2e6",
          "state": "DISAMBIGUATION",
          "next_action": "SHOW_ALTERNATIVES",
          "disambiguation_type": "VEHICLE_MISMATCH",
          "reason": "The part is clearly a conventional 12V starter motor. The specified vehicle uses an integrated Hybrid Starter Generator instead.",
          "alternatives": [
            {
              "name": "Starter Motor",
              "part_number": "7b55e74a-fd97-4d89-bc5e-434cc8263d81",
              "confidence": 0.95,
              "vehicle_compatible": false
            }
          ],
          "questions": [
            {
              "id": "vehicle_mismatch",
              "question": "This part does not appear to fit your vehicle. How would you like to continue?",
              "options": ["Continue with the scanned part"]
            }
          ]
        }
        """.utf8)
        let dto = try JSONDecoder().decode(ScanProcessDataDTO.self, from: json)
        guard case .disambiguation(let scanId, let kind, let reason, let alternatives, let questions) = dto.toModel() else {
            Issue.record("expected .disambiguation")
            return
        }
        #expect(scanId == "472a3bac-6d6c-43c0-932b-548b886cb2e6")
        #expect(kind == .vehicleMismatch)
        #expect(reason?.isEmpty == false)
        #expect(alternatives.first?.vehicleCompatible == false)
        #expect(questions.count == 1)
    }

    /// CRITERIA splits keep the generic chooser; and payloads predating
    /// `disambiguation_type` / `vehicle_compatible` must decode identically
    /// (both fields absent → `.criteria`, nil compatibility).
    @Test func criteriaAndLegacyPayloadsDegradeToCriteria() throws {
        let json = Data("""
        {
          "scan_id": "s-1",
          "state": "DISAMBIGUATION",
          "next_action": "SHOW_ALTERNATIVES",
          "alternatives": [
            { "name": "Brake Caliper — Bromsok (1-kolvs)", "part_number": "cand-1", "confidence": 0.97 }
          ],
          "questions": []
        }
        """.utf8)
        let dto = try JSONDecoder().decode(ScanProcessDataDTO.self, from: json)
        guard case .disambiguation(_, let kind, let reason, let alternatives, _) = dto.toModel() else {
            Issue.record("expected .disambiguation")
            return
        }
        #expect(kind == .criteria)
        #expect(reason == nil)
        #expect(alternatives.first?.vehicleCompatible == nil)
    }

    @Test func unknownDisambiguationTypeDegradesToCriteria() {
        #expect(DisambiguationKindDomain(wireValue: "SOMETHING_NEW") == .criteria)
        #expect(DisambiguationKindDomain(wireValue: nil) == .criteria)
        #expect(DisambiguationKindDomain(wireValue: "VEHICLE_MISMATCH") == .vehicleMismatch)
    }
}
