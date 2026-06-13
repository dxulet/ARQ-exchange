import Foundation
import XCTest
@testable import ARQExchange

final class RatesRepositoryTests: XCTestCase {
    func testLoadReturnsFreshCacheWithoutNetworkRequest() async throws {
        let now = Date(timeIntervalSince1970: 100)
        let cachedSnapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: now.addingTimeInterval(-30)
        )
        let cache = InMemoryRatesSnapshotCache(snapshot: cachedSnapshot)
        let service = RepositoryMockRatesService(discoveryResult: .failure(.expected))
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            freshnessInterval: 60,
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot(forceRefresh: false)

        XCTAssertEqual(result.source, .freshCache)
        XCTAssertEqual(result.snapshot, cachedSnapshot)
        let discoveryRequestCount = await service.discoveryRequestCount
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(discoveryRequestCount, 0)
        XCTAssertEqual(requestedRateCurrencies, [])
    }

    func testForceRefreshBypassesFreshCacheAndStoresNetworkSnapshot() async throws {
        let now = Date(timeIntervalSince1970: 200)
        let cachedSnapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: now
        )
        let cache = InMemoryRatesSnapshotCache(snapshot: cachedSnapshot)
        let service = RepositoryMockRatesService(
            discoveryResult: .success(CurrencyDiscoveryResult(currencies: [.cop], source: .remote)),
            ratesResult: .success([TestFixtures.copRate])
        )
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            freshnessInterval: 60,
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot(forceRefresh: true)

        XCTAssertEqual(result.source, .network)
        XCTAssertEqual(result.snapshot.availableCurrencies, [.cop])
        XCTAssertEqual(result.snapshot.ratesByCurrency, [.cop: TestFixtures.copRate])
        XCTAssertEqual(result.snapshot.fetchedAt, now)
        let storedSnapshot = await cache.snapshot()
        let discoveryRequestCount = await service.discoveryRequestCount
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(storedSnapshot, result.snapshot)
        XCTAssertEqual(discoveryRequestCount, 1)
        XCTAssertEqual(requestedRateCurrencies, [[.cop]])
    }

    func testNetworkFailureReturnsStaleCache() async throws {
        let now = Date(timeIntervalSince1970: 500)
        let cachedSnapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: now.addingTimeInterval(-120)
        )
        let cache = InMemoryRatesSnapshotCache(snapshot: cachedSnapshot)
        let service = RepositoryMockRatesService(discoveryResult: .failure(.expected))
        let diagnostics = DiagnosticsRecorder()
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            diagnostics: diagnostics,
            freshnessInterval: 60,
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot(forceRefresh: false)

        XCTAssertEqual(result.source, .staleCache)
        XCTAssertEqual(result.snapshot, cachedSnapshot)
        let discoveryRequestCount = await service.discoveryRequestCount
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(discoveryRequestCount, 1)
        XCTAssertEqual(requestedRateCurrencies, [])
        XCTAssertEqual(diagnostics.events, [.staleCacheServed])
    }

    func testCurrencyDiscoveryTimeoutFallsBackToLocalCurrencies() async throws {
        let now = Date(timeIntervalSince1970: 700)
        let cache = InMemoryRatesSnapshotCache()
        let service = RepositoryMockRatesService(
            discoveryResult: .success(CurrencyDiscoveryResult(currencies: [.mxn], source: .remote)),
            ratesResult: .success([TestFixtures.mxnRate]),
            discoveryDelayNanoseconds: 100_000_000
        )
        let diagnostics = DiagnosticsRecorder()
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            diagnostics: diagnostics,
            fallbackDelayNanoseconds: 1,
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot(forceRefresh: false)

        XCTAssertEqual(result.source, .network)
        XCTAssertEqual(result.snapshot.availableCurrencies, CurrencyCode.localCurrencies)
        XCTAssertEqual(result.snapshot.currencyDiscoverySource, .fallbackTimeout)
        XCTAssertEqual(result.snapshot.ratesByCurrency, [.mxn: TestFixtures.mxnRate])
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(requestedRateCurrencies, [CurrencyCode.localCurrencies])
        XCTAssertEqual(diagnostics.events, [.currencyDiscoveryFallback(source: .fallbackTimeout)])
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

private final class DiagnosticsRecorder: RatesDiagnostics, @unchecked Sendable {
    private let lock = NSLock()
    private var recordedEvents: [RatesDiagnosticEvent] = []

    var events: [RatesDiagnosticEvent] {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents
    }

    func record(_ event: RatesDiagnosticEvent) {
        lock.lock()
        recordedEvents.append(event)
        lock.unlock()
    }
}
