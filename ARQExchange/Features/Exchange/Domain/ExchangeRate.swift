import Foundation

struct ExchangeRate: Equatable, Codable, Sendable {
    let base: CurrencyCode
    let quote: CurrencyCode
    let bid: Decimal
    let ask: Decimal
    let timestamp: String
}
