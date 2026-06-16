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
            previousState: previousState
        )

        XCTAssertEqual(state.loadState, .loaded)
        XCTAssertEqual(state.availableCurrencies, [.ars, .mxn])
        XCTAssertEqual(state.selectedCurrency, .mxn)
        XCTAssertEqual(state.bottomAmountText, "184.1")
    }

    func testAmountUpdatedSanitizesInputAndCalculatesInactiveAmount() {
        let loadedState = ExchangeCalculatorState(
            loadState: .loaded,
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            topCurrency: .usdc,
            bottomCurrency: .mxn
        )

        let state = reducer.amountUpdated(
            rawText: "$9,999",
            field: .top,
            in: loadedState
        )

        XCTAssertEqual(state.topAmountText, "9,999")
        XCTAssertEqual(state.bottomAmountText, "184,078.59")
        XCTAssertEqual(state.activeField, .top)
    }

    func testAmountUpdatedNormalizesLeadingZeroesInActiveInput() {
        let loadedState = ExchangeCalculatorState(
            loadState: .loaded,
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            topCurrency: .usdc,
            bottomCurrency: .mxn
        )

        let state = reducer.amountUpdated(
            rawText: "02437",
            field: .top,
            in: loadedState
        )

        XCTAssertEqual(state.topAmountText, "2,437")
        XCTAssertEqual(state.bottomAmountText, "44,864.44")
    }

    func testCurrenciesSwappedPreservesUSDcAmountAndUsesAskRateForLocalTop() {
        let loadedState = ExchangeCalculatorState(
            loadState: .loaded,
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            topCurrency: .usdc,
            bottomCurrency: .mxn,
            topAmountText: "9,999",
            bottomAmountText: "184,078.59",
            activeField: .top
        )

        let state = reducer.currenciesSwapped(in: loadedState)

        XCTAssertEqual(state.topCurrency, .mxn)
        XCTAssertEqual(state.bottomCurrency, .usdc)
        XCTAssertEqual(state.topAmountText, "184,391.56")
        XCTAssertEqual(state.bottomAmountText, "9,999")
        XCTAssertEqual(state.activeField, .bottom)
    }
}
