import Foundation
import Testing
@testable import ZomPart

@Suite
struct APIErrorParserTests {

    @Test func parsesKnownErrorCode() {
        let body = Data("""
        { "success": false, "error": { "code": "PART_LOOKUP_FAILED", "title": "Not Found", "message": "x" } }
        """.utf8)
        #expect(APIErrorParser.code(from: body) == .partLookupFailed)
    }

    @Test func unknownCodeReturnsNil() {
        let body = Data("""
        { "success": false, "error": { "code": "SOMETHING_NEW" } }
        """.utf8)
        #expect(APIErrorParser.code(from: body) == nil)
    }

    @Test func parsesRetryAfterFromMeta() {
        let body = Data("""
        {
          "success": false,
          "error": { "code": "RATE_LIMIT_EXCEEDED" },
          "meta": { "request_id": "req_1", "timestamp": "2026-07-07T10:00:00Z", "retry_after": 42 }
        }
        """.utf8)
        #expect(APIErrorParser.retryAfterSeconds(from: body) == 42)
    }

    @Test func retryAfterNilWhenAbsentOrGarbage() {
        let noMeta = Data("{ \"success\": false }".utf8)
        #expect(APIErrorParser.retryAfterSeconds(from: noMeta) == nil)
        #expect(APIErrorParser.retryAfterSeconds(from: Data("not json".utf8)) == nil)
    }
}
