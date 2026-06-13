import XCTest
@testable import ARQExchange

final class ExchangeCalculatorStateReducerTests: XCTestCase {
    private let reducer = ExchangeCalculatorStateReducer()

    func testLoadedStateSelectsFirstCurrencyWithRateAndPreservesActiveInput() {
        let previousState = ExchangeCalculatorState(
            topAmountText: "10",
            activeField: .top
        )
        let snapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.ars, .mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate]
        )

        let state = reducer.loadedState(
            from: snapshot,
            previousState: previousState,
            ratesSource: .staleCache
        )

        XCTAssertEqual(state.loadState, .loaded)
        XCTAssertEqual(state.availableCurrencies, [.ars, .mxn])
        XCTAssertEqual(state.selectedCurrency, .mxn)
        XCTAssertEqual(state.bottomAmountText, "184.1")
        XCTAssertTrue(state.isUsingStaleRates)
    }

    func testAmountUpdatedSanitizesInputAndCalculatesInactiveAmount() {
        let loadedState = ExchangeCalculatorState(
            loadState: .loaded,
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            topCurrency: .usdc,
            bottomCurrency: .mxn
        )

        let amountUpdate = reducer.amountUpdated(
            rawText: "$9,999",
            field: .top,
            in: loadedState
        )

        XCTAssertEqual(amountUpdate.sanitizedText, "9999")
        XCTAssertEqual(amountUpdate.state.topAmountText, "9999")
        XCTAssertEqual(amountUpdate.state.bottomAmountText, "184,078.59")
        XCTAssertEqual(amountUpdate.state.activeField, .top)
    }

    func testCurrenciesSwappedPreservesUSDcAmountAndUsesAskRateForLocalTop() {
        let loadedState = ExchangeCalculatorState(
            loadState: .loaded,
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            topCurrency: .usdc,
            bottomCurrency: .mxn,
            topAmountText: "9999",
            bottomAmountText: "184,078.59",
            activeField: .top
        )

        let state = reducer.currenciesSwapped(in: loadedState)

        XCTAssertEqual(state.topCurrency, .mxn)
        XCTAssertEqual(state.bottomCurrency, .usdc)
        XCTAssertEqual(state.topAmountText, "184,391.56")
        XCTAssertEqual(state.bottomAmountText, "9999")
        XCTAssertEqual(state.activeField, .bottom)
    }
}
