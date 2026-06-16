import XCTest
@testable import ARQExchange

@MainActor
final class ExchangeCalculatorViewModelTests: XCTestCase {
    func testLoadPublishesCurrenciesRatesAndDefaultSelection() async {
        let viewModel = makeViewModel(result: .success(.loadedSnapshot()))

        await viewModel.load().value

        XCTAssertEqual(viewModel.state.loadState, .loaded)
        XCTAssertEqual(viewModel.state.availableCurrencies, [.mxn, .cop])
        XCTAssertEqual(viewModel.state.selectedCurrency, .mxn)
        XCTAssertEqual(viewModel.state.topCurrency, .usdc)
        XCTAssertEqual(viewModel.state.bottomCurrency, .mxn)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 18.4097 MXN")
    }

    func testLoadFailurePublishesFailedState() async {
        let viewModel = makeViewModel(result: .failure(TestError.expected))

        await viewModel.load().value

        XCTAssertEqual(
            viewModel.state.loadState,
            .failed(message: ExchangeCalculatorCopy.loadFailure)
        )
    }

    func testLoadCancellationKeepsPreviousState() async {
        let viewModel = makeViewModel(result: .failure(CancellationError()))

        await viewModel.load().value

        XCTAssertEqual(viewModel.state.loadState, .idle)
    }

    func testRetryReloadsAfterFailure() async {
        let viewModel = makeViewModel(
            results: [
                .failure(TestError.expected),
                .success(.loadedSnapshot(availableCurrencies: [.mxn], ratesByCurrency: [.mxn: TestFixtures.mxnRate]))
            ]
        )

        await viewModel.load().value
        await viewModel.retry().value

        XCTAssertEqual(viewModel.state.loadState, .loaded)
        XCTAssertEqual(viewModel.state.selectedCurrency, .mxn)
    }

    func testStaleRepositoryResultMarksStateAndDisplaysNormalTicker() async {
        let fetchedAt = Date(timeIntervalSince1970: 1_780_000_000)
        let viewModel = makeViewModel(
            result: .success(
                .loadedSnapshot(
                    availableCurrencies: [.mxn],
                    ratesByCurrency: [.mxn: TestFixtures.mxnRate],
                    source: .staleCache,
                    fetchedAt: fetchedAt
                )
            )
        )

        await viewModel.load().value

        XCTAssertEqual(viewModel.state.loadState, .loaded)
        XCTAssertTrue(viewModel.state.isUsingStaleRates)
        XCTAssertEqual(viewModel.state.ratesFetchedAt, fetchedAt)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 18.4097 MXN")
    }

    func testEnteringTopUSDcCalculatesBottomLocalAmount() async {
        let viewModel = await loadedViewModel()

        viewModel.updateAmount(TestFixtures.usdcInput, field: .top)

        XCTAssertEqual(viewModel.state.topAmountText, "9,999")
        XCTAssertEqual(viewModel.state.bottomAmountText, "184,078.59")
    }

    func testEnteringBottomLocalCalculatesTopUSDcAmount() async {
        let viewModel = await loadedViewModel()

        viewModel.updateAmount(TestFixtures.localInput, field: .bottom)

        XCTAssertEqual(viewModel.state.topAmountText, "10,017")
        XCTAssertEqual(viewModel.state.bottomAmountText, "184,410")
    }

    func testSelectingCurrencyRecalculatesEnteredAmount() async {
        let viewModel = await loadedViewModel()
        viewModel.updateAmount(TestFixtures.usdcInput, field: .top)

        viewModel.selectCurrency(.cop)

        XCTAssertEqual(viewModel.state.selectedCurrency, .cop)
        XCTAssertEqual(viewModel.state.bottomCurrency, .cop)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 3,832.42 COP")
        XCTAssertEqual(viewModel.state.topAmountText, "9,999")
        XCTAssertEqual(viewModel.state.bottomAmountText, "38,320,367.58")
    }

    func testSwapPreservesUSDcAmountAndUsesAskRateForLocalTop() async {
        let viewModel = await loadedViewModel()
        viewModel.updateAmount(TestFixtures.usdcInput, field: .top)

        viewModel.swapCurrencies()

        XCTAssertEqual(viewModel.state.topCurrency, .mxn)
        XCTAssertEqual(viewModel.state.bottomCurrency, .usdc)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 18.441 MXN")
        XCTAssertEqual(viewModel.state.topAmountText, "184,391.56")
        XCTAssertEqual(viewModel.state.bottomAmountText, "9,999")
    }

    func testClearingActiveInputClearsConvertedAmount() async {
        let viewModel = await loadedViewModel()
        viewModel.updateAmount(TestFixtures.usdcInput, field: .top)

        viewModel.updateAmount("", field: .top)

        XCTAssertEqual(viewModel.state.topAmountText, "")
        XCTAssertEqual(viewModel.state.bottomAmountText, "")
    }

    private func loadedViewModel() async -> ExchangeCalculatorViewModel {
        let viewModel = makeViewModel(result: .success(.loadedSnapshot()))
        await viewModel.load().value
        return viewModel
    }

    private func makeViewModel(result: Result<RatesRepositoryResult, Error>) -> ExchangeCalculatorViewModel {
        makeViewModel(results: [result])
    }

    private func makeViewModel(results: [Result<RatesRepositoryResult, Error>]) -> ExchangeCalculatorViewModel {
        ExchangeCalculatorViewModel(
            ratesRepository: MockRatesRepository(results: results)
        )
    }
}

private enum TestError: Error, Sendable {
    case expected
}

private actor MockRatesRepository: RatesRepository {
    private var results: [Result<RatesRepositoryResult, Error>]

    init(results: [Result<RatesRepositoryResult, Error>]) {
        self.results = results
    }

    func loadRatesSnapshot() async throws -> RatesRepositoryResult {
        guard !results.isEmpty else {
            throw TestError.expected
        }

        return try results.removeFirst().get()
    }
}

private extension RatesRepositoryResult {
    static func loadedSnapshot(
        availableCurrencies: [CurrencyCode] = [.mxn, .cop],
        ratesByCurrency: [CurrencyCode: ExchangeRate] = [
            .mxn: TestFixtures.mxnRate,
            .cop: TestFixtures.copRate
        ],
        source: RatesSnapshotSource = .network,
        fetchedAt: Date = Date(timeIntervalSince1970: 0),
        currencyDiscoverySource: CurrencyDiscoverySource = .remote
    ) -> RatesRepositoryResult {
        RatesRepositoryResult(
            snapshot: ExchangeRatesSnapshot(
                availableCurrencies: availableCurrencies,
                ratesByCurrency: ratesByCurrency,
                fetchedAt: fetchedAt,
                currencyDiscoverySource: currencyDiscoverySource
            ),
            source: source
        )
    }
}
