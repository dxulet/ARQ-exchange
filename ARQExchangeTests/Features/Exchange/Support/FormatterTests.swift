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

    func testRateFormatterUsesGroupingAndFourFractionDigits() {
        let value = TestFixtures.decimal("1505.2275")

        XCTAssertEqual(RateFormatter.string(from: value, quote: .ars), "1 USDc = 1,505.2275 ARS")
    }

    func testRateFormatterHandlesZero() {
        XCTAssertEqual(RateFormatter.string(from: Decimal(0), quote: .mxn), "1 USDc = 0 MXN")
    }
}
