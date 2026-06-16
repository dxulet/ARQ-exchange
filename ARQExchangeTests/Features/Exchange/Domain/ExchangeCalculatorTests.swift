import XCTest
@testable import ARQExchange

final class ExchangeCalculatorTests: XCTestCase {
    private let calculator = ExchangeCalculator()
    private let mxnRate = ExchangeRate(
        base: .usdc,
        quote: .mxn,
        bid: TestFixtures.decimal("17.4382"),
        ask: TestFixtures.decimal("17.4418"),
        timestamp: TestFixtures.timestamp
    )

    func testUSDcToLocalWithBidMultipliesByBid() throws {
        let result = try calculator.convert(ConversionRequest(
            amount: Decimal(10),
            sourceCurrency: .usdc,
            targetCurrency: .mxn,
            rate: mxnRate,
            quoteSide: .bid
        ))

        XCTAssertEqual(result, TestFixtures.decimal("174.382"))
    }

    func testLocalToUSDcWithBidDividesByBid() throws {
        let result = try calculator.convert(ConversionRequest(
            amount: TestFixtures.decimal("174.382"),
            sourceCurrency: .mxn,
            targetCurrency: .usdc,
            rate: mxnRate,
            quoteSide: .bid
        ))

        XCTAssertEqual(result, Decimal(10))
    }

    func testLocalToUSDcWithAskDividesByAsk() throws {
        let result = try calculator.convert(ConversionRequest(
            amount: TestFixtures.decimal("174.418"),
            sourceCurrency: .mxn,
            targetCurrency: .usdc,
            rate: mxnRate,
            quoteSide: .ask
        ))

        XCTAssertEqual(result, Decimal(10))
    }

    func testUSDcToLocalWithAskMultipliesByAsk() throws {
        let result = try calculator.convert(ConversionRequest(
            amount: Decimal(10),
            sourceCurrency: .usdc,
            targetCurrency: .mxn,
            rate: mxnRate,
            quoteSide: .ask
        ))

        XCTAssertEqual(result, TestFixtures.decimal("174.418"))
    }

    func testNonPositiveRateThrows() {
        let invalidRate = ExchangeRate(
            base: .usdc,
            quote: .mxn,
            bid: Decimal(0),
            ask: TestFixtures.decimal("-17.4418"),
            timestamp: TestFixtures.timestamp
        )

        XCTAssertThrowsError(try calculator.convert(ConversionRequest(
            amount: Decimal(10),
            sourceCurrency: .usdc,
            targetCurrency: .mxn,
            rate: invalidRate,
            quoteSide: .bid
        ))) { error in
            XCTAssertEqual(error as? ExchangeCalculationError, .nonPositiveRate)
        }
    }

    func testUnsupportedPairThrows() {
        XCTAssertThrowsError(try calculator.convert(ConversionRequest(
            amount: Decimal(10),
            sourceCurrency: .ars,
            targetCurrency: .mxn,
            rate: mxnRate,
            quoteSide: .bid
        ))) { error in
            XCTAssertEqual(
                error as? ExchangeCalculationError,
                .unsupportedPair(source: .ars, target: .mxn)
            )
        }
    }
}
