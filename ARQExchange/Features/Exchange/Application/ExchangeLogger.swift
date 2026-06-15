import Foundation
import OSLog

enum ExchangeLogEvent: Equatable, Sendable {
    case ratesLoadSucceeded(source: RatesSnapshotSource, currencyDiscoverySource: CurrencyDiscoverySource)
    case ratesLoadFailed
    case retryTapped
    case currencySelected(CurrencyCode)
    case currenciesSwapped
    case firstAmountEdited
    case currencyDiscoveryFallback(source: CurrencyDiscoverySource)
    case tickerMappingSkipped(book: String, reason: String)
    case staleCacheServed
    case cacheReadFailed(reason: String)
    case cacheWriteFailed(reason: String)
}

struct ExchangeLogger: Sendable {
    private let record: @Sendable (ExchangeLogEvent) -> Void

    init(record: @escaping @Sendable (ExchangeLogEvent) -> Void = { _ in }) {
        self.record = record
    }

    func log(_ event: ExchangeLogEvent) {
        record(event)
    }

    static let disabled = ExchangeLogger()

    static func osLog(subsystem: String = Bundle.main.bundleIdentifier ?? "ARQExchange") -> ExchangeLogger {
        let analyticsLogger = Logger(subsystem: subsystem, category: "Exchange")
        let diagnosticsLogger = Logger(subsystem: subsystem, category: "ExchangeDiagnostics")

        return ExchangeLogger { event in
            event.write(analyticsLogger: analyticsLogger, diagnosticsLogger: diagnosticsLogger)
        }
    }
}

private extension ExchangeLogEvent {
    func write(analyticsLogger: Logger, diagnosticsLogger: Logger) {
        if isDiagnostic {
            writeDiagnostic(to: diagnosticsLogger)
        } else {
            writeAnalytics(to: analyticsLogger)
        }
    }

    var isDiagnostic: Bool {
        switch self {
        case .currencyDiscoveryFallback, .tickerMappingSkipped, .staleCacheServed, .cacheReadFailed, .cacheWriteFailed:
            return true
        case .ratesLoadSucceeded, .ratesLoadFailed, .retryTapped, .currencySelected, .currenciesSwapped, .firstAmountEdited:
            return false
        }
    }

    func writeAnalytics(to logger: Logger) {
        switch self {
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
        case .currencyDiscoveryFallback, .tickerMappingSkipped, .staleCacheServed, .cacheReadFailed, .cacheWriteFailed:
            break
        }
    }

    func writeDiagnostic(to logger: Logger) {
        switch self {
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
        case .ratesLoadSucceeded, .ratesLoadFailed, .retryTapped, .currencySelected, .currenciesSwapped, .firstAmountEdited:
            break
        }
    }
}
