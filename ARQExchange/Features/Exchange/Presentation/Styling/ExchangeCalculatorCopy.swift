import Foundation

enum ExchangeCalculatorCopy {
    static let title = String(localized: "Exchange calculator", comment: "Main screen title")
    static let sheetTitle = String(localized: "Choose currency", comment: "Currency picker title")
    static let retryTitle = String(localized: "Retry", comment: "Retry button title")
    static let amountPlaceholder = String(localized: "0", comment: "Amount field placeholder")
    static let rateUnavailable = String(localized: "Rate unavailable", comment: "Shown when a currency has no exchange rate")
    static let loadFailure = String(localized: "We couldn't load exchange rates. Please try again.", comment: "Rates load failure message")

    static let swapAccessibilityLabel = String(localized: "Swap currencies", comment: "Swap button accessibility label")
    static let closeAccessibilityLabel = String(localized: "Close", comment: "Close button accessibility label")
    static let retryAccessibilityLabel = String(localized: "Retry loading exchange rates", comment: "Retry button accessibility label")

    static func amountAccessibilityLabel(for currency: CurrencyCode) -> String {
        String(localized: "\(currency.rawValue) amount", comment: "Amount field accessibility label")
    }

    static func selectCurrencyAccessibilityLabel(for currency: CurrencyCode) -> String {
        String(localized: "Select \(currency.rawValue) currency", comment: "Currency picker row accessibility label")
    }

    static func unavailableCurrencyAccessibilityValue(for currency: CurrencyCode) -> String {
        String(localized: "\(currency.rawValue) rate unavailable", comment: "Unavailable currency accessibility value")
    }

    static func selectedCurrencyAccessibilityValue(for currency: CurrencyCode) -> String {
        String(localized: "\(currency.rawValue) selected", comment: "Selected currency accessibility value")
    }

    static func staleRateText(_ rateText: String) -> String {
        String(localized: "\(rateText) - last available rate", comment: "Stale exchange rate label")
    }
}
