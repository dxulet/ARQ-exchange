import XCTest
@testable import ARQExchange

final class CurrencyMetadataTests: XCTestCase {
    func testKnownCurrencyMetadataResolvesDisplaySupport() {
        let metadata = CurrencyMetadataCatalog.metadata(for: .mxn)

        XCTAssertEqual(metadata.code, .mxn)
        XCTAssertEqual(metadata.displayName, "Mexican Peso")
        XCTAssertEqual(metadata.flag, .mxFlag)
    }

    func testUnknownCurrencyMetadataFallsBackToCurrencyCode() {
        let currency = CurrencyCode(rawValue: "CLP")

        let metadata = CurrencyMetadataCatalog.metadata(for: currency)

        XCTAssertEqual(metadata.code, currency)
        XCTAssertEqual(metadata.displayName, "CLP")
        XCTAssertNil(metadata.flag)
    }
}
