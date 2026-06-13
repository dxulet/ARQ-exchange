import Combine
import Foundation

@MainActor
final class ExchangeCalculatorViewModel: ObservableObject {
    @Published private(set) var state: ExchangeCalculatorState

    private let loadingUseCase: RatesLoadingUseCase
    private let analyticsClient: AnalyticsClient
    private let stateReducer: ExchangeCalculatorStateReducer
    private var hasTrackedFirstAmountEdit = false

    init(
        loadingUseCase: RatesLoadingUseCase,
        initialState: ExchangeCalculatorState = ExchangeCalculatorState(),
        analyticsClient: AnalyticsClient = NoopAnalyticsClient(),
        stateReducer: ExchangeCalculatorStateReducer = ExchangeCalculatorStateReducer()
    ) {
        self.loadingUseCase = loadingUseCase
        self.analyticsClient = analyticsClient
        self.stateReducer = stateReducer
        state = initialState
    }

    var rateText: String {
        guard let displayRate = state.displayedRate else {
            return ExchangeCalculatorCopy.rateUnavailable
        }

        let rateText = RateFormatter.string(from: displayRate, quote: state.selectedCurrency)
        return state.isUsingStaleRates ? ExchangeCalculatorCopy.staleRateText(rateText) : rateText
    }

    func loadIfNeeded() async {
        guard state.loadState != .loaded, state.loadState != .loading else {
            return
        }

        await load()
    }

    func retry() async {
        analyticsClient.track(.retryTapped)
        await load(forceRefresh: true)
    }

    func load(forceRefresh: Bool = false) async {
        let previousState = state
        setState(mutating: { $0.loadState = .loading })

        do {
            let result = try await loadingUseCase.loadRatesSnapshot(forceRefresh: forceRefresh)
            applyLoadedSnapshot(result)
            analyticsClient.track(
                .ratesLoadSucceeded(
                    source: result.source,
                    currencyDiscoverySource: result.snapshot.currencyDiscoverySource
                )
            )
        } catch is CancellationError {
            setState(previousState)
        } catch {
            applyLoadFailure(using: previousState)
        }
    }

    func updateAmount(_ rawText: String, field: InputField) {
        let amountUpdate = stateReducer.amountUpdated(rawText: rawText, field: field, in: state)
        trackFirstAmountEditIfNeeded(amountUpdate.sanitizedText)
        setState(amountUpdate.state)
    }

    func selectCurrency(_ currency: CurrencyCode) {
        guard !currency.isUSDc else {
            return
        }

        analyticsClient.track(.currencySelected(currency))
        setState(stateReducer.currencySelected(currency, in: state))
    }

    func swapCurrencies() {
        analyticsClient.track(.currenciesSwapped)
        setState(stateReducer.currenciesSwapped(in: state))
    }

    private func applyLoadedSnapshot(_ result: RatesRepositoryResult) {
        setState(
            stateReducer.loadedState(
                from: result.snapshot,
                previousState: state,
                ratesSource: result.source
            )
        )
    }

    private func applyLoadFailure(using previousState: ExchangeCalculatorState) {
        setState(
            stateReducer.failedState(
                from: previousState,
                message: ExchangeCalculatorCopy.loadFailure
            )
        )
        analyticsClient.track(.ratesLoadFailed)
    }

    private func trackFirstAmountEditIfNeeded(_ sanitizedText: String) {
        guard !hasTrackedFirstAmountEdit, !sanitizedText.isEmpty else {
            return
        }

        hasTrackedFirstAmountEdit = true
        analyticsClient.track(.firstAmountEdited)
    }

    private func setState(_ nextState: ExchangeCalculatorState) {
        guard nextState != state else {
            return
        }

        state = nextState
    }

    private func setState(mutating update: (inout ExchangeCalculatorState) -> Void) {
        var draftState = state
        update(&draftState)
        setState(draftState)
    }
}
