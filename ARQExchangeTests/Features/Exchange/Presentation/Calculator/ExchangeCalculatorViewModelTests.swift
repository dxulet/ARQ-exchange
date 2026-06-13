import XCTest
@testable import ARQExchange

@MainActor
final class ExchangeCalculatorViewModelTests: XCTestCase {
    func testLoadPublishesCurrenciesRatesAndDefaultSelection() async {
        let viewModel = makeViewModel(
            service: MockRatesService(
                discoveryResult: CurrencyDiscoveryResult(currencies: [.mxn, .cop], source: .remote),
                rates: [TestFixtures.mxnRate, TestFixtures.copRate]
            )
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state.loadState, .loaded)
        XCTAssertEqual(viewModel.state.availableCurrencies, [.mxn, .cop])
        XCTAssertEqual(viewModel.state.selectedCurrency, .mxn)
        XCTAssertEqual(viewModel.state.topCurrency, .usdc)
        XCTAssertEqual(viewModel.state.bottomCurrency, .mxn)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 18.4097 MXN")
    }

    func testLoadFailurePublishesFailedState() async {
        let viewModel = makeViewModel(
            service: MockRatesService(loadError: TestError.expected)
        )

        await viewModel.load()

        XCTAssertEqual(
            viewModel.state.loadState,
            .failed(message: ExchangeCalculatorCopy.loadFailure)
        )
    }

    func testLoadCancellationKeepsPreviousState() async {
        let viewModel = makeViewModel(
            service: MockRatesService(loadError: CancellationError())
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state.loadState, .idle)
    }

    func testRetryReloadsAfterFailure() async {
        let service = SequenceRatesService(
            loadResults: [
                .failure(TestError.expected),
                .success((
                    discoveryResult: CurrencyDiscoveryResult(currencies: [.mxn], source: .remote),
                    rates: [TestFixtures.mxnRate]
                ))
            ]
        )
        let viewModel = makeViewModel(service: service)

        await viewModel.load()
        await viewModel.retry()

        XCTAssertEqual(viewModel.state.loadState, .loaded)
        XCTAssertEqual(viewModel.state.selectedCurrency, .mxn)
    }

    func testLoadFallsBackBeforeFetchingRatesWhenServiceReturnsNoCurrencies() async {
        let viewModel = makeViewModel(
            service: MockRatesService(
                discoveryResult: CurrencyDiscoveryResult(currencies: CurrencyCode.localCurrencies, source: .fallbackEmpty),
                rates: [TestFixtures.mxnRate],
                expectedRateRequest: CurrencyCode.localCurrencies
            )
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state.loadState, .loaded)
        XCTAssertEqual(viewModel.state.availableCurrencies, CurrencyCode.localCurrencies)
        XCTAssertEqual(viewModel.state.selectedCurrency, .mxn)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 18.4097 MXN")
    }

    func testLoadKeepsFirstRateWhenServiceReturnsDuplicateQuotes() async {
        let duplicateMXNRate = ExchangeRate(
            base: .usdc,
            quote: .mxn,
            bid: TestFixtures.decimal("99"),
            ask: TestFixtures.decimal("100"),
            timestamp: TestFixtures.timestamp
        )
        let viewModel = makeViewModel(
            service: MockRatesService(
                discoveryResult: CurrencyDiscoveryResult(currencies: [.mxn], source: .remote),
                rates: [TestFixtures.mxnRate, duplicateMXNRate]
            )
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state.loadState, .loaded)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 18.4097 MXN")
    }

    func testEnteringTopUSDcCalculatesBottomLocalAmount() async {
        let viewModel = await loadedViewModel()

        viewModel.updateAmount(TestFixtures.usdcInput, field: .top)

        XCTAssertEqual(viewModel.state.topAmountText, TestFixtures.usdcInput)
        XCTAssertEqual(viewModel.state.bottomAmountText, "184,078.59")
    }

    func testEnteringBottomLocalCalculatesTopUSDcAmount() async {
        let viewModel = await loadedViewModel()

        viewModel.updateAmount(TestFixtures.localInput, field: .bottom)

        XCTAssertEqual(viewModel.state.topAmountText, "10,017")
        XCTAssertEqual(viewModel.state.bottomAmountText, TestFixtures.localInput)
    }

    func testSelectingCurrencyRecalculatesEnteredAmount() async {
        let viewModel = await loadedViewModel()
        viewModel.updateAmount(TestFixtures.usdcInput, field: .top)

        viewModel.selectCurrency(.cop)

        XCTAssertEqual(viewModel.state.selectedCurrency, .cop)
        XCTAssertEqual(viewModel.state.bottomCurrency, .cop)
        XCTAssertEqual(viewModel.rateText, "1 USDc = 3,832.42 COP")
        XCTAssertEqual(viewModel.state.topAmountText, TestFixtures.usdcInput)
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
        XCTAssertEqual(viewModel.state.bottomAmountText, TestFixtures.usdcInput)
    }

    func testClearingActiveInputClearsConvertedAmount() async {
        let viewModel = await loadedViewModel()
        viewModel.updateAmount(TestFixtures.usdcInput, field: .top)

        viewModel.updateAmount("", field: .top)

        XCTAssertEqual(viewModel.state.topAmountText, "")
        XCTAssertEqual(viewModel.state.bottomAmountText, "")
    }

    func testCurrencySelectionChangesSelectedCurrency() async {
        let viewModel = await loadedViewModel()

        viewModel.selectCurrency(.cop)

        XCTAssertEqual(viewModel.state.selectedCurrency, .cop)
    }

    private func loadedViewModel() async -> ExchangeCalculatorViewModel {
        let viewModel = makeViewModel(
            service: MockRatesService(
                discoveryResult: CurrencyDiscoveryResult(currencies: [.mxn, .cop], source: .remote),
                rates: [TestFixtures.mxnRate, TestFixtures.copRate]
            )
        )
        await viewModel.load()
        return viewModel
    }

    private func makeViewModel(service: RatesService) -> ExchangeCalculatorViewModel {
        ExchangeCalculatorViewModel(
            loadingUseCase: RatesLoadingUseCase(
                ratesRepository: LiveRatesRepository(
                    ratesService: service,
                    cache: InMemoryRatesSnapshotCache()
                )
            )
        )
    }
}

private enum TestError: Error, Sendable {
    case expected
}

private struct MockRatesService: RatesService {
    var discoveryResult = CurrencyDiscoveryResult(currencies: [.mxn], source: .remote)
    var rates: [ExchangeRate] = []
    var loadError: (any Error & Sendable)?
    var expectedRateRequest: [CurrencyCode]?

    func fetchAvailableCurrencies() async throws -> CurrencyDiscoveryResult {
        if let loadError {
            throw loadError
        }

        return discoveryResult
    }

    func fetchRates(for currencies: [CurrencyCode]) async throws -> [ExchangeRate] {
        if let loadError {
            throw loadError
        }

        if let expectedRateRequest {
            XCTAssertEqual(currencies, expectedRateRequest)
        }

        return rates
    }
}

private actor SequenceRatesService: RatesService {
    typealias LoadPayload = (discoveryResult: CurrencyDiscoveryResult, rates: [ExchangeRate])

    private var loadResults: [Result<LoadPayload, TestError>]
    private var currentPayload: LoadPayload?

    init(loadResults: [Result<LoadPayload, TestError>]) {
        self.loadResults = loadResults
    }

    func fetchAvailableCurrencies() async throws -> CurrencyDiscoveryResult {
        let payload = try nextPayload()
        currentPayload = payload
        return payload.discoveryResult
    }

    func fetchRates(for currencies: [CurrencyCode]) async throws -> [ExchangeRate] {
        guard let currentPayload else {
            throw TestError.expected
        }

        return currentPayload.rates
    }

    private func nextPayload() throws -> LoadPayload {
        guard !loadResults.isEmpty else {
            throw TestError.expected
        }

        return try loadResults.removeFirst().get()
    }
}
