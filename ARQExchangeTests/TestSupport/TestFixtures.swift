import Foundation
import XCTest
@testable import ARQExchange

enum TestFixtures {
    static let apiBaseURL = makeURL("https://api.dolarapp.dev")
    static let timestamp = "2026-06-10T12:35:55.356249099"
    static let usdcInput = "9999"
    static let localInput = "184410"

    static let mxnRate = ExchangeRate(
        base: .usdc,
        quote: .mxn,
        bid: decimal("18.4097"),
        ask: decimal("18.4410"),
        timestamp: timestamp
    )

    static let copRate = ExchangeRate(
        base: .usdc,
        quote: .cop,
        bid: decimal("3832.42"),
        ask: decimal("3890.83"),
        timestamp: timestamp
    )

    static let apiMXNRate = ExchangeRate(
        base: .usdc,
        quote: .mxn,
        bid: decimal("17.4382000000"),
        ask: decimal("17.4418000000"),
        timestamp: timestamp
    )

    static let apiMXNTicker = TickerResponse(
        ask: "17.4418000000",
        bid: "17.4382000000",
        currencyPairCode: "usdc_mxn",
        timestamp: timestamp
    )

    static func decimal(_ value: String, file: StaticString = #filePath, line: UInt = #line) -> Decimal {
        guard let decimal = DecimalParser.apiDecimal(from: value) else {
            XCTFail("Invalid decimal fixture: \(value)", file: file, line: line)
            return 0
        }

        return decimal
    }

    static func data(_ value: String, file: StaticString = #filePath, line: UInt = #line) -> Data {
        guard let data = value.data(using: .utf8) else {
            XCTFail("Invalid UTF-8 fixture", file: file, line: line)
            return Data()
        }

        return data
    }

    private static func makeURL(_ value: String, file: StaticString = #filePath, line: UInt = #line) -> URL {
        guard let url = URL(string: value) else {
            XCTFail("Invalid URL fixture: \(value)", file: file, line: line)
            return URL(fileURLWithPath: "/")
        }

        return url
    }
}
