import Foundation

enum RateFormatter {
    static func string(from value: Decimal, quote: CurrencyCode) -> String {
        let formattedRate = DisplayNumberFormatter.rateString(from: value)
        return String(localized: "1 USDc = \(formattedRate) \(quote.rawValue)", comment: "Exchange rate label")
    }
}
