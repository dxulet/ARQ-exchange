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

    func testActiveInputFormatterGroupsWholeNumbers() {
        XCTAssertEqual(AmountFormatter.activeInputString(from: "9999"), "9,999")
        XCTAssertEqual(AmountFormatter.activeInputString(from: "$1234567.8900"), "1,234,567.8900")
    }

    func testActiveInputFormatterNormalizesLeadingZeroes() {
        XCTAssertEqual(AmountFormatter.activeInputString(from: "02437"), "2,437")
        XCTAssertEqual(AmountFormatter.activeInputString(from: "0000"), "0")
        XCTAssertEqual(AmountFormatter.activeInputString(from: "0000.45"), "0.45")
    }

    func testActiveInputFormatterKeepsPartialDecimalInput() {
        XCTAssertEqual(AmountFormatter.activeInputString(from: "."), "0.")
        XCTAssertEqual(AmountFormatter.activeInputString(from: "0."), "0.")
        XCTAssertEqual(AmountFormatter.activeInputString(from: "0.0"), "0.0")
    }

    func testRateFormatterUsesSixSignificantDigits() {
        let value = TestFixtures.decimal("1505.2275")

        XCTAssertEqual(RateFormatter.string(from: value, quote: .ars), "1 USDc = 1,505.23 ARS")
    }

    func testRateFormatterHandlesZero() {
        XCTAssertEqual(RateFormatter.string(from: Decimal(0), quote: .mxn), "1 USDc = 0 MXN")
    }
}
