import Foundation

enum ExchangeLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(message: String)
}

struct CurrencyPickerItem: Identifiable, Equatable, Sendable {
    let currency: CurrencyCode
    let metadata: CurrencyMetadata
    let isSelected: Bool
    let isSelectable: Bool

    var id: String {
        currency.id
    }
}

struct ExchangeCalculatorState: Equatable, Sendable {
    var loadState: ExchangeLoadState = .idle
    var availableCurrencies: [CurrencyCode] = CurrencyCode.localCurrencies
    var ratesByCurrency: [CurrencyCode: ExchangeRate] = [:]
    var topCurrency: CurrencyCode = .usdc
    var bottomCurrency: CurrencyCode = .mxn
    var topAmountText = ""
    var bottomAmountText = ""
    var activeField: InputField?
    var isUsingStaleRates = false

    var selectedCurrency: CurrencyCode {
        topCurrency == .usdc ? bottomCurrency : topCurrency
    }

    var displayQuoteSide: QuoteSide {
        topCurrency == .usdc ? .bid : .ask
    }

    var currentRate: ExchangeRate? {
        ratesByCurrency[selectedCurrency]
    }

    var displayedRate: Decimal? {
        guard let currentRate else {
            return nil
        }

        return displayQuoteSide == .bid ? currentRate.bid : currentRate.ask
    }

    var currencyPickerItems: [CurrencyPickerItem] {
        availableCurrencies.map { currency in
            let metadata = CurrencyMetadataCatalog.metadata(for: currency)
            return CurrencyPickerItem(
                currency: currency,
                metadata: metadata,
                isSelected: currency == selectedCurrency,
                isSelectable: ratesByCurrency[currency] != nil
            )
        }
    }

    func currency(for field: InputField) -> CurrencyCode {
        field == .top ? topCurrency : bottomCurrency
    }

    func amountText(for field: InputField) -> String {
        field == .top ? topAmountText : bottomAmountText
    }

    mutating func setAmountText(_ text: String, for field: InputField) {
        switch field {
        case .top:
            topAmountText = text
        case .bottom:
            bottomAmountText = text
        }
    }
}
