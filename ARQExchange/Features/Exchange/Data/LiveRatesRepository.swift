import Foundation

struct LiveRatesRepository: RatesRepository {
    static let defaultStaleCacheMaxAge: TimeInterval = 15 * 60

    private let ratesService: RatesService
    private let cache: RatesSnapshotCaching
    private let logger: ExchangeLogger
    private let staleCacheMaxAge: TimeInterval
    private let fallbackDelayNanoseconds: UInt64
    private let now: @Sendable () -> Date

    init(
        ratesService: RatesService,
        cache: RatesSnapshotCaching = DiskRatesSnapshotCache(),
        logger: ExchangeLogger = .disabled,
        staleCacheMaxAge: TimeInterval = LiveRatesRepository.defaultStaleCacheMaxAge,
        fallbackDelayNanoseconds: UInt64 = 750_000_000,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.ratesService = ratesService
        self.cache = cache
        self.logger = logger
        self.staleCacheMaxAge = staleCacheMaxAge
        self.fallbackDelayNanoseconds = fallbackDelayNanoseconds
        self.now = now
    }

    func loadRatesSnapshot() async throws -> RatesRepositoryResult {
        do {
            let snapshot = try await fetchNetworkSnapshot()
            await cache.store(snapshot)
            return RatesRepositoryResult(snapshot: snapshot, source: .network)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let cachedSnapshot = await freshCachedSnapshot() {
                return RatesRepositoryResult(snapshot: cachedSnapshot, source: .staleCache)
            }

            throw error
        }
    }

    private func fetchNetworkSnapshot() async throws -> ExchangeRatesSnapshot {
        let discovery = try await availableCurrenciesWithFallback()
        recordDiscoveryFallbackIfNeeded(discovery)
        let rates = try await ratesService.fetchRates(for: discovery.currencies)

        return ExchangeRatesSnapshot(
            availableCurrencies: discovery.currencies,
            ratesByCurrency: ratesByCurrency(from: rates),
            fetchedAt: now(),
            currencyDiscoverySource: discovery.source
        )
    }

    private func availableCurrenciesWithFallback() async throws -> CurrencyDiscoveryResult {
        try await withThrowingTaskGroup(of: CurrencyDiscoveryResult.self) { group in
            group.addTask {
                try await ratesService.fetchAvailableCurrencies()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: fallbackDelayNanoseconds)
                return CurrencyDiscoveryResult(currencies: CurrencyCode.localCurrencies, source: .fallbackTimeout)
            }

            guard let result = try await group.next() else {
                group.cancelAll()
                return CurrencyDiscoveryResult(currencies: CurrencyCode.localCurrencies, source: .fallbackTimeout)
            }

            group.cancelAll()
            return result
        }
    }

    private func ratesByCurrency(from rates: [ExchangeRate]) -> [CurrencyCode: ExchangeRate] {
        Dictionary(
            rates.map { ($0.quote, $0) },
            uniquingKeysWith: { existingRate, _ in existingRate }
        )
    }

    private func recordDiscoveryFallbackIfNeeded(_ discovery: CurrencyDiscoveryResult) {
        guard discovery.source == .fallbackTimeout else {
            return
        }

        logger.log(.currencyDiscoveryFallback(source: discovery.source))
    }

    private func freshCachedSnapshot() async -> ExchangeRatesSnapshot? {
        guard let cachedSnapshot = await cache.snapshot() else {
            return nil
        }

        let cacheAge = now().timeIntervalSince(cachedSnapshot.fetchedAt)
        guard cacheAge <= staleCacheMaxAge else {
            logger.log(.staleCacheExpired)
            return nil
        }

        logger.log(.staleCacheServed)
        return cachedSnapshot
    }
}
