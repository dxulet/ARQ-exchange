import Foundation

struct LiveRatesRepository: RatesRepository {
    static let defaultFallbackDelayNanoseconds: UInt64 = 750_000_000

    private let ratesService: RatesService
    private let logger: ExchangeLogger
    private let fallbackDelayNanoseconds: UInt64

    init(
        ratesService: RatesService,
        logger: ExchangeLogger = .disabled,
        fallbackDelayNanoseconds: UInt64 = LiveRatesRepository.defaultFallbackDelayNanoseconds
    ) {
        self.ratesService = ratesService
        self.logger = logger
        self.fallbackDelayNanoseconds = fallbackDelayNanoseconds
    }

    // MARK: - RatesRepository

    func loadRatesSnapshot() async throws -> ExchangeRatesSnapshot {
        try await fetchNetworkSnapshot()
    }

    // MARK: - Private

    private func fetchNetworkSnapshot() async throws -> ExchangeRatesSnapshot {
        let discovery = try await availableCurrenciesWithFallback()
        recordDiscoveryFallbackIfNeeded(discovery)
        let rates = try await ratesService.fetchRates(for: discovery.currencies)

        return ExchangeRatesSnapshot(
            availableCurrencies: discovery.currencies,
            ratesByCurrency: ratesByCurrency(from: rates),
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
}
