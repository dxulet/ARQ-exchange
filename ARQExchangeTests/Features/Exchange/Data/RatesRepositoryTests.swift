import XCTest
@testable import ARQExchange

final class RatesRepositoryTests: XCTestCase {
    func testLoadFetchesNetworkSnapshot() async throws {
        let service = RepositoryMockRatesService(
            discoveryResult: .success(CurrencyDiscoveryResult(currencies: [.cop], source: .remote)),
            ratesResult: .success([TestFixtures.copRate])
        )
        let repository = LiveRatesRepository(ratesService: service)

        let snapshot = try await repository.loadRatesSnapshot()

        XCTAssertEqual(snapshot.availableCurrencies, [.cop])
        XCTAssertEqual(snapshot.ratesByCurrency, [.cop: TestFixtures.copRate])
        let discoveryRequestCount = await service.discoveryRequestCount
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(discoveryRequestCount, 1)
        XCTAssertEqual(requestedRateCurrencies, [[.cop]])
    }

    func testNetworkFailureThrowsError() async {
        let service = RepositoryMockRatesService(discoveryResult: .failure(.expected))
        let repository = LiveRatesRepository(ratesService: service)

        do {
            _ = try await repository.loadRatesSnapshot()
            XCTFail("Expected load failure")
        } catch {
            XCTAssertEqual(error as? RepositoryTestError, .expected)
        }

        let discoveryRequestCount = await service.discoveryRequestCount
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(discoveryRequestCount, 1)
        XCTAssertEqual(requestedRateCurrencies, [])
    }

    func testLoadKeepsFirstRateWhenNetworkReturnsDuplicateQuotes() async throws {
        let duplicateMXNRate = ExchangeRate(
            base: .usdc,
            quote: .mxn,
            bid: TestFixtures.decimal("99"),
            ask: TestFixtures.decimal("100"),
            timestamp: TestFixtures.timestamp
        )
        let service = RepositoryMockRatesService(
            discoveryResult: .success(CurrencyDiscoveryResult(currencies: [.mxn], source: .remote)),
            ratesResult: .success([TestFixtures.mxnRate, duplicateMXNRate])
        )
        let repository = LiveRatesRepository(ratesService: service)

        let snapshot = try await repository.loadRatesSnapshot()

        XCTAssertEqual(snapshot.ratesByCurrency, [.mxn: TestFixtures.mxnRate])
    }

    func testCurrencyDiscoveryTimeoutFallsBackToLocalCurrencies() async throws {
        let service = RepositoryMockRatesService(
            discoveryResult: .success(CurrencyDiscoveryResult(currencies: [.mxn], source: .remote)),
            ratesResult: .success([TestFixtures.mxnRate]),
            discoveryDelayNanoseconds: 100_000_000
        )
        let logRecorder = TestLogRecorder()
        let repository = LiveRatesRepository(
            ratesService: service,
            logger: logRecorder.logger,
            fallbackDelayNanoseconds: 1
        )

        let snapshot = try await repository.loadRatesSnapshot()

        XCTAssertEqual(snapshot.availableCurrencies, CurrencyCode.localCurrencies)
        XCTAssertEqual(snapshot.currencyDiscoverySource, .fallbackTimeout)
        XCTAssertEqual(snapshot.ratesByCurrency, [.mxn: TestFixtures.mxnRate])
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(requestedRateCurrencies, [CurrencyCode.localCurrencies])
        XCTAssertEqual(logRecorder.events, [.currencyDiscoveryFallback(source: .fallbackTimeout)])
    }
}

private actor RepositoryMockRatesService: RatesService {
    private let discoveryResult: MockResult<CurrencyDiscoveryResult>
    private let ratesResult: MockResult<[ExchangeRate]>
    private let discoveryDelayNanoseconds: UInt64

    private(set) var discoveryRequestCount = 0
    private(set) var requestedRateCurrencies: [[CurrencyCode]] = []

    init(
        discoveryResult: MockResult<CurrencyDiscoveryResult> = .success(
            CurrencyDiscoveryResult(currencies: [.mxn], source: .remote)
        ),
        ratesResult: MockResult<[ExchangeRate]> = .success([TestFixtures.mxnRate]),
        discoveryDelayNanoseconds: UInt64 = 0
    ) {
        self.discoveryResult = discoveryResult
        self.ratesResult = ratesResult
        self.discoveryDelayNanoseconds = discoveryDelayNanoseconds
    }

    func fetchAvailableCurrencies() async throws -> CurrencyDiscoveryResult {
        discoveryRequestCount += 1

        if discoveryDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: discoveryDelayNanoseconds)
        }

        return try discoveryResult.value()
    }

    func fetchRates(for currencies: [CurrencyCode]) async throws -> [ExchangeRate] {
        requestedRateCurrencies.append(currencies)
        return try ratesResult.value()
    }
}

private enum MockResult<Success: Sendable>: Sendable {
    case success(Success)
    case failure(RepositoryTestError)

    func value() throws -> Success {
        switch self {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}

private enum RepositoryTestError: Error, Sendable {
    case expected
}
