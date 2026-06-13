import Foundation
import OSLog

enum AnalyticsEvent: Equatable, Sendable {
    case ratesLoadSucceeded(source: RatesSnapshotSource, currencyDiscoverySource: CurrencyDiscoverySource)
    case ratesLoadFailed
    case retryTapped
    case currencySelected(CurrencyCode)
    case currenciesSwapped
    case firstAmountEdited
}

protocol AnalyticsClient: Sendable {
    func track(_ event: AnalyticsEvent)
}

enum RatesDiagnosticEvent: Equatable, Sendable {
    case currencyDiscoveryFallback(source: CurrencyDiscoverySource)
    case tickerMappingSkipped(book: String, reason: String)
    case staleCacheServed
    case cacheReadFailed(reason: String)
    case cacheWriteFailed(reason: String)
}

protocol RatesDiagnostics: Sendable {
    func record(_ event: RatesDiagnosticEvent)
}

struct NoopAnalyticsClient: AnalyticsClient {
    func track(_ event: AnalyticsEvent) {}
}

struct NoopRatesDiagnostics: RatesDiagnostics {
    func record(_ event: RatesDiagnosticEvent) {}
}

struct OSLogAnalyticsClient: AnalyticsClient {
    private let logger: Logger

    init(
        logger: Logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "ARQExchange",
            category: "Exchange"
        )
    ) {
        self.logger = logger
    }

    func track(_ event: AnalyticsEvent) {
        switch event {
        case let .ratesLoadSucceeded(source, currencyDiscoverySource):
            let discoverySource = currencyDiscoverySource.rawValue
            logger.info("rates_load_succeeded source=\(source.rawValue, privacy: .public) discovery=\(discoverySource, privacy: .public)")
        case .ratesLoadFailed:
            logger.error("rates_load_failed")
        case .retryTapped:
            logger.info("retry_tapped")
        case let .currencySelected(currency):
            logger.info("currency_selected currency=\(currency.rawValue, privacy: .public)")
        case .currenciesSwapped:
            logger.info("currencies_swapped")
        case .firstAmountEdited:
            logger.info("first_amount_edited")
        }
    }
}

struct OSLogRatesDiagnostics: RatesDiagnostics {
    private let logger: Logger

    init(
        logger: Logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "ARQExchange",
            category: "ExchangeDiagnostics"
        )
    ) {
        self.logger = logger
    }

    func record(_ event: RatesDiagnosticEvent) {
        switch event {
        case let .currencyDiscoveryFallback(source):
            logger.warning("currency_discovery_fallback source=\(source.rawValue, privacy: .public)")
        case let .tickerMappingSkipped(book, reason):
            logger.warning("ticker_mapping_skipped book=\(book, privacy: .public) reason=\(reason, privacy: .public)")
        case .staleCacheServed:
            logger.warning("stale_cache_served")
        case let .cacheReadFailed(reason):
            logger.warning("rates_cache_read_failed reason=\(reason, privacy: .public)")
        case let .cacheWriteFailed(reason):
            logger.error("rates_cache_write_failed reason=\(reason, privacy: .public)")
        }
    }
}
