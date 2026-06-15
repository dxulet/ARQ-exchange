import XCTest
@testable import ARQExchange

final class InputSanitizerTests: XCTestCase {
    func testRemovesCurrencySymbolsAndGroupingSeparators() {
        XCTAssertEqual(InputSanitizer.sanitize("$1,234.56"), "1234.56")
    }

    func testAllowsOnlyOneDecimalSeparator() {
        XCTAssertEqual(InputSanitizer.sanitize("12.3.4"), "12.34")
    }

    func testAllowsPartialDecimalInput() {
        XCTAssertEqual(InputSanitizer.sanitize("."), ".")
    }

    func testKeepsDotAsDecimalSeparator() {
        XCTAssertEqual(InputSanitizer.sanitize("123.45"), "123.45")
    }

    func testTreatsCommaAsGroupingNoiseNotDecimalSeparator() {
        XCTAssertEqual(InputSanitizer.sanitize("123,45"), "12345")
        XCTAssertEqual(DecimalParser.userInputDecimal(from: "123,45"), TestFixtures.decimal("12345"))
    }

    func testHandlesEmptyInput() {
        XCTAssertEqual(InputSanitizer.sanitize(""), "")
    }

    func testIgnoresInvalidCharacters() {
        XCTAssertEqual(InputSanitizer.sanitize("a1b2c"), "12")
    }

    func testParsesUserInputWithStableDecimalSeparator() {
        XCTAssertEqual(DecimalParser.userInputDecimal(from: "$1,234.56"), TestFixtures.decimal("1234.56"))
    }

    func testRejectsInvalidAPIDecimal() {
        XCTAssertNil(DecimalParser.apiDecimal(from: "17.4abc"))
    }
}
