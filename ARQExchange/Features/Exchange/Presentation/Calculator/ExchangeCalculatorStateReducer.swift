struct ExchangeCalculatorStateReducer: Sendable {
    private let calculator: ExchangeCalculator

    init(calculator: ExchangeCalculator = ExchangeCalculator()) {
        self.calculator = calculator
    }

    func loadedState(
        from snapshot: ExchangeRatesSnapshot,
        previousState: ExchangeCalculatorState,
        ratesSource: RatesSnapshotSource
    ) -> ExchangeCalculatorState {
        var loadedState = ExchangeCalculatorState(
            loadState: .loaded,
            availableCurrencies: snapshot.availableCurrencies,
            ratesByCurrency: snapshot.ratesByCurrency,
            topCurrency: .usdc,
            bottomCurrency: snapshot.selectedCurrency,
            topAmountText: previousState.topAmountText,
            bottomAmountText: previousState.bottomAmountText,
            activeField: previousState.activeField,
            isUsingStaleRates: ratesSource == .staleCache,
            ratesFetchedAt: snapshot.fetchedAt
        )
        updateConvertedAmount(in: &loadedState)
        return loadedState
    }

    func failedState(from previousState: ExchangeCalculatorState, message: String) -> ExchangeCalculatorState {
        var failedState = previousState
        failedState.loadState = .failed(message: message)
        return failedState
    }

    func amountUpdated(
        rawText: String,
        field: InputField,
        in currentState: ExchangeCalculatorState
    ) -> ExchangeCalculatorState {
        let sanitizedText = InputSanitizer.sanitize(rawText)
        var nextState = currentState
        nextState.activeField = field

        guard !sanitizedText.isEmpty else {
            nextState.topAmountText = ""
            nextState.bottomAmountText = ""
            return nextState
        }

        nextState.setAmountText(sanitizedText, for: field)
        updateConvertedAmount(in: &nextState)

        return nextState
    }

    func currencySelected(_ currency: CurrencyCode, in currentState: ExchangeCalculatorState) -> ExchangeCalculatorState {
        guard !currency.isUSDc else {
            return currentState
        }

        var nextState = currentState

        if nextState.topCurrency.isUSDc {
            nextState.bottomCurrency = currency
        } else {
            nextState.topCurrency = currency
        }

        updateConvertedAmount(in: &nextState)
        return nextState
    }

    func currenciesSwapped(in currentState: ExchangeCalculatorState) -> ExchangeCalculatorState {
        var nextState = currentState
        let previousTopCurrency = nextState.topCurrency
        let previousTopAmount = nextState.topAmountText
        let previousBottomAmount = nextState.bottomAmountText

        swapCurrencyPositions(in: &nextState)
        restoreAmountAfterSwap(
            previousTopCurrency: previousTopCurrency,
            previousTopAmount: previousTopAmount,
            previousBottomAmount: previousBottomAmount,
            in: &nextState
        )
        updateConvertedAmount(in: &nextState)

        return nextState
    }

    private func swapCurrencyPositions(in state: inout ExchangeCalculatorState) {
        let previousTopCurrency = state.topCurrency
        state.topCurrency = state.bottomCurrency
        state.bottomCurrency = previousTopCurrency
    }

    private func restoreAmountAfterSwap(
        previousTopCurrency: CurrencyCode,
        previousTopAmount: String,
        previousBottomAmount: String,
        in state: inout ExchangeCalculatorState
    ) {
        if previousTopCurrency.isUSDc {
            state.topAmountText = ""
            state.bottomAmountText = previousTopAmount
            state.activeField = previousTopAmount.isEmpty ? nil : .bottom
        } else {
            state.topAmountText = previousBottomAmount
            state.bottomAmountText = ""
            state.activeField = previousBottomAmount.isEmpty ? nil : .top
        }
    }

    private func updateConvertedAmount(in state: inout ExchangeCalculatorState) {
        guard let formattedConversion = formattedConversion(for: state) else {
            clearInactiveAmount(in: &state)
            return
        }

        if let activeField = state.activeField {
            state.setAmountText(formattedConversion, for: inactiveField(for: activeField))
        }
    }

    private func formattedConversion(for state: ExchangeCalculatorState) -> String? {
        guard
            let activeField = state.activeField,
            let amount = DecimalParser.userInputDecimal(from: state.amountText(for: activeField)),
            let rate = state.currentRate
        else {
            return nil
        }

        let inactiveField = inactiveField(for: activeField)
        let conversionRequest = ConversionRequest(
            amount: amount,
            sourceCurrency: state.currency(for: activeField),
            targetCurrency: state.currency(for: inactiveField),
            rate: rate,
            quoteSide: state.displayQuoteSide
        )

        return try? AmountFormatter.string(from: calculator.convert(conversionRequest))
    }

    private func clearInactiveAmount(in state: inout ExchangeCalculatorState) {
        guard let activeField = state.activeField else {
            return
        }

        state.setAmountText("", for: inactiveField(for: activeField))
    }

    private func inactiveField(for field: InputField) -> InputField {
        field == .top ? .bottom : .top
    }
}
