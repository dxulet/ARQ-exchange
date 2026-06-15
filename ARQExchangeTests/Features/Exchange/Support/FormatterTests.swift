import XCTest
@testable import ARQExchange

final class FormatterTests: XCTestCase {
    func testAmountFormatterUsesGroupingAndTwoFractionDigits() {
        let value = TestFixtures.decimal("184065.59")

        XCTAssertEqual(AmountFormatter.string(from: value), "184,065.59")
    }

    func testAmountFormatterDoesNotForceTrailingZeroes() {
        XCTAssertEqual(AmountFormatter.string(from: Decimal(9999)), "9,999")
    }

    func testRateFormatterUsesSixSignificantDigits() {
        let value = TestFixtures.decimal("1505.2275")

        XCTAssertEqual(RateFormatter.string(from: value, quote: .ars), "1 USDc = 1,505.23 ARS")
    }

    func testRateFormatterKeepsSixDigitCOPRate() {
        let value = TestFixtures.decimal("3832.42")

        XCTAssertEqual(RateFormatter.string(from: value, quote: .cop), "1 USDc = 3,832.42 COP")
    }

    func testRateFormatterHandlesZero() {
        XCTAssertEqual(RateFormatter.string(from: Decimal(0), quote: .mxn), "1 USDc = 0 MXN")
    }
}
