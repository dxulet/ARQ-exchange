@MainActor
protocol CurrencyPickerPresenting {
    func presentCurrencyPicker()
}

@MainActor
protocol CurrencySelecting {
    func selectCurrency(_ currency: CurrencyCode)
}

@MainActor
protocol ExchangeCalculatorActionHandling: CurrencyPickerPresenting, CurrencySelecting {
    func retryRatesLoad()
    func swapCurrencies()
}
