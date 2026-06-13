enum CurrencyDiscoverySource: String, Codable, Equatable, Sendable {
    case remote
    case fallbackTimeout
    case fallbackError
    case fallbackEmpty
}

struct CurrencyDiscoveryResult: Equatable, Sendable {
    let currencies: [CurrencyCode]
    let source: CurrencyDiscoverySource
}

protocol RatesService: Sendable {
    func fetchAvailableCurrencies() async throws -> CurrencyDiscoveryResult
    func fetchRates(for currencies: [CurrencyCode]) async throws -> [ExchangeRate]
}
