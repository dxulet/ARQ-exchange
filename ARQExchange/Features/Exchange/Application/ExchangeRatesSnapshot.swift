import Foundation

struct ExchangeRatesSnapshot: Equatable, Sendable {
    let availableCurrencies: [CurrencyCode]
    let ratesByCurrency: [CurrencyCode: ExchangeRate]
    let fetchedAt: Date
    let currencyDiscoverySource: CurrencyDiscoverySource

    init(
        availableCurrencies: [CurrencyCode],
        ratesByCurrency: [CurrencyCode: ExchangeRate],
        fetchedAt: Date = Date(timeIntervalSince1970: 0),
        currencyDiscoverySource: CurrencyDiscoverySource = .remote
    ) {
        self.availableCurrencies = availableCurrencies
        self.ratesByCurrency = ratesByCurrency
        self.fetchedAt = fetchedAt
        self.currencyDiscoverySource = currencyDiscoverySource
    }

    var selectedCurrency: CurrencyCode {
        availableCurrencies.first(where: { ratesByCurrency[$0] != nil })
            ?? ratesByCurrency.keys.sorted { $0.rawValue < $1.rawValue }.first
            ?? .mxn
    }
}
