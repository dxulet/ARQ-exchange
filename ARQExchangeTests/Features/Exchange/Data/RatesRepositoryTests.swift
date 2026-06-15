import Foundation
import XCTest
@testable import ARQExchange

final class RatesRepositoryTests: XCTestCase {
    func testLoadFetchesNetworkEvenWhenCacheIsFresh() async throws {
        let now = Date(timeIntervalSince1970: 100)
        let cachedSnapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: now.addingTimeInterval(-30)
        )
        let cache = InMemoryRatesSnapshotCache(snapshot: cachedSnapshot)
        let service = RepositoryMockRatesService(
            discoveryResult: .success(CurrencyDiscoveryResult(currencies: [.cop], source: .remote)),
            ratesResult: .success([TestFixtures.copRate])
        )
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot()

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

    func testLoadStoresNetworkSnapshot() async throws {
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
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot()

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

    func testNetworkFailureReturnsFreshStaleCache() async throws {
        let now = Date(timeIntervalSince1970: 500)
        let cachedSnapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: now.addingTimeInterval(-120)
        )
        let cache = InMemoryRatesSnapshotCache(snapshot: cachedSnapshot)
        let service = RepositoryMockRatesService(discoveryResult: .failure(.expected))
        let logRecorder = TestLogRecorder()
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            logger: logRecorder.logger,
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot()

        XCTAssertEqual(result.source, .staleCache)
        XCTAssertEqual(result.snapshot, cachedSnapshot)
        let discoveryRequestCount = await service.discoveryRequestCount
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(discoveryRequestCount, 1)
        XCTAssertEqual(requestedRateCurrencies, [])
        XCTAssertEqual(logRecorder.events, [.staleCacheServed])
    }

    func testNetworkFailureRejectsExpiredStaleCache() async {
        let now = Date(timeIntervalSince1970: 2_000)
        let cachedSnapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: now.addingTimeInterval(-LiveRatesRepository.defaultStaleCacheMaxAge - 1)
        )
        let cache = InMemoryRatesSnapshotCache(snapshot: cachedSnapshot)
        let service = RepositoryMockRatesService(discoveryResult: .failure(.expected))
        let logRecorder = TestLogRecorder()
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            logger: logRecorder.logger,
            now: { now }
        )

        do {
            _ = try await repository.loadRatesSnapshot()
            XCTFail("Expected expired cache to be rejected")
        } catch {
            XCTAssertEqual(error as? RepositoryTestError, .expected)
        }

        XCTAssertEqual(logRecorder.events, [.staleCacheExpired])
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
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: InMemoryRatesSnapshotCache()
        )

        let result = try await repository.loadRatesSnapshot()

        XCTAssertEqual(result.snapshot.ratesByCurrency, [.mxn: TestFixtures.mxnRate])
    }

    func testDiskCacheStoreLoadRoundTripPersistsSchemaVersion() async throws {
        let snapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn, .cop],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate, .cop: TestFixtures.copRate],
            fetchedAt: Date(timeIntervalSince1970: 1_780_000_000),
            currencyDiscoverySource: .remote
        )
        let fileURL = try temporaryCacheFileURL()
        let cache = DiskRatesSnapshotCache(fileURL: fileURL)

        await cache.store(snapshot)

        let reloadedCache = DiskRatesSnapshotCache(fileURL: fileURL)
        let reloadedSnapshot = await reloadedCache.snapshot()
        XCTAssertEqual(reloadedSnapshot, snapshot)
        let data = try Data(contentsOf: fileURL)
        let payloadText = try XCTUnwrap(String(bytes: data, encoding: .utf8))
        XCTAssertTrue(payloadText.contains(#""schemaVersion":1"#))
    }

    func testDiskCacheLoadsUnversionedSnapshot() async throws {
        let snapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: Date(timeIntervalSince1970: 1_780_000_000),
            currencyDiscoverySource: .remote
        )
        let fileURL = try temporaryCacheFileURL()
        let payload = RatesSnapshotPayload(snapshot: snapshot)
        let data = try JSONEncoder().encode(payload)
        try data.write(to: fileURL)

        let cache = DiskRatesSnapshotCache(fileURL: fileURL)

        let reloadedSnapshot = await cache.snapshot()
        XCTAssertEqual(reloadedSnapshot, snapshot)
    }

    func testDiskCacheCorruptPayloadFailsGracefully() async throws {
        let fileURL = try temporaryCacheFileURL()
        try Data("{not-json".utf8).write(to: fileURL)
        let logRecorder = TestLogRecorder()
        let cache = DiskRatesSnapshotCache(fileURL: fileURL, logger: logRecorder.logger)

        let snapshot = await cache.snapshot()

        XCTAssertNil(snapshot)
        XCTAssertEqual(logRecorder.events.count, 1)
        guard case .cacheReadFailed = logRecorder.events.first else {
            return XCTFail("Expected cache read failure diagnostic")
        }
    }

    func testDiskCacheUnknownSchemaPayloadFailsGracefully() async throws {
        let snapshot = ExchangeRatesSnapshot(
            availableCurrencies: [.mxn],
            ratesByCurrency: [.mxn: TestFixtures.mxnRate],
            fetchedAt: Date(timeIntervalSince1970: 1_780_000_000),
            currencyDiscoverySource: .remote
        )
        let fileURL = try temporaryCacheFileURL()
        let payload = RatesSnapshotPayload(schemaVersion: 999, snapshot: snapshot)
        let data = try JSONEncoder().encode(payload)
        try data.write(to: fileURL)
        let logRecorder = TestLogRecorder()
        let cache = DiskRatesSnapshotCache(fileURL: fileURL, logger: logRecorder.logger)

        let loadedSnapshot = await cache.snapshot()

        XCTAssertNil(loadedSnapshot)
        XCTAssertEqual(logRecorder.events.count, 1)
        guard case let .cacheReadFailed(reason) = logRecorder.events.first else {
            return XCTFail("Expected cache read failure diagnostic")
        }
        XCTAssertTrue(reason.contains("unsupportedSchemaVersion"))
    }

    func testCurrencyDiscoveryTimeoutFallsBackToLocalCurrencies() async throws {
        let now = Date(timeIntervalSince1970: 700)
        let cache = InMemoryRatesSnapshotCache()
        let service = RepositoryMockRatesService(
            discoveryResult: .success(CurrencyDiscoveryResult(currencies: [.mxn], source: .remote)),
            ratesResult: .success([TestFixtures.mxnRate]),
            discoveryDelayNanoseconds: 100_000_000
        )
        let logRecorder = TestLogRecorder()
        let repository = LiveRatesRepository(
            ratesService: service,
            cache: cache,
            logger: logRecorder.logger,
            fallbackDelayNanoseconds: 1,
            now: { now }
        )

        let result = try await repository.loadRatesSnapshot()

        XCTAssertEqual(result.source, .network)
        XCTAssertEqual(result.snapshot.availableCurrencies, CurrencyCode.localCurrencies)
        XCTAssertEqual(result.snapshot.currencyDiscoverySource, .fallbackTimeout)
        XCTAssertEqual(result.snapshot.ratesByCurrency, [.mxn: TestFixtures.mxnRate])
        let requestedRateCurrencies = await service.requestedRateCurrencies
        XCTAssertEqual(requestedRateCurrencies, [CurrencyCode.localCurrencies])
        XCTAssertEqual(logRecorder.events, [.currencyDiscoveryFallback(source: .fallbackTimeout)])
    }

    private func temporaryCacheFileURL() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        return directoryURL.appendingPathComponent("exchange-rates-snapshot.json")
    }
}

private struct RatesSnapshotPayload: Encodable {
    let schemaVersion: Int?
    let availableCurrencies: [CurrencyCode]
    let rates: [ExchangeRate]
    let fetchedAt: Date
    let currencyDiscoverySource: CurrencyDiscoverySource

    init(schemaVersion: Int? = nil, snapshot: ExchangeRatesSnapshot) {
        self.schemaVersion = schemaVersion
        availableCurrencies = snapshot.availableCurrencies
        rates = snapshot.ratesByCurrency.values.sorted { $0.quote.rawValue < $1.quote.rawValue }
        fetchedAt = snapshot.fetchedAt
        currencyDiscoverySource = snapshot.currencyDiscoverySource
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
