import XCTest
@testable import ARQExchange

final class CurrencyFlagCatalogTests: XCTestCase {
    func testKnownCurrencyResolvesFlag() {
        XCTAssertEqual(CurrencyFlagCatalog.flag(for: .mxn), .mxFlag)
    }

    func testUnknownCurrencyReturnsNoFlag() {
        let currency = CurrencyCode(rawValue: "CLP")

        XCTAssertNil(CurrencyFlagCatalog.flag(for: currency))
    }
}
