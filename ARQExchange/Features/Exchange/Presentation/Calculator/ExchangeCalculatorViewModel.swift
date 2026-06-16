import Combine
import Foundation

@MainActor
final class ExchangeCalculatorViewModel: ObservableObject {
    @Published private(set) var state: ExchangeCalculatorState

    private let ratesRepository: RatesRepository
    private let logger: ExchangeLogger
    private let stateReducer: ExchangeCalculatorStateReducer
    private var loadTask: Task<Void, Never>?
    private var loadRequestID = 0

    init(
        ratesRepository: RatesRepository,
        initialState: ExchangeCalculatorState = ExchangeCalculatorState(),
        logger: ExchangeLogger = .disabled,
        stateReducer: ExchangeCalculatorStateReducer = ExchangeCalculatorStateReducer()
    ) {
        self.ratesRepository = ratesRepository
        self.logger = logger
        self.stateReducer = stateReducer
        state = initialState
    }

    // MARK: - Derived State

    var rateText: String {
        guard let displayRate = state.displayedRate else {
            return ExchangeCalculatorCopy.rateUnavailable
        }

        return RateFormatter.string(from: displayRate, quote: state.selectedCurrency)
    }

    var currencyPickerItems: [CurrencyPickerItem] {
        state.availableCurrencies.map { currency in
            CurrencyPickerItem(
                currency: currency,
                flag: CurrencyFlagCatalog.flag(for: currency),
                isSelected: currency == state.selectedCurrency,
                isSelectable: state.hasRate(for: currency)
            )
        }
    }

    // MARK: - Loading

    @discardableResult
    func loadIfNeeded() -> Task<Void, Never>? {
        guard state.loadState != .loaded, state.loadState != .loading else {
            return nil
        }

        return load()
    }

    @discardableResult
    func retry() -> Task<Void, Never> {
        return load()
    }

    @discardableResult
    func load() -> Task<Void, Never> {
        loadTask?.cancel()
        loadRequestID += 1
        let requestID = loadRequestID
        let previousState = state
        setState(mutating: { $0.loadState = .loading })

        let task = Task { [weak self, previousState, requestID] in
            guard let self else {
                return
            }

            do {
                let snapshot = try await ratesRepository.loadRatesSnapshot()
                try Task.checkCancellation()
                guard isCurrentLoad(requestID) else {
                    return
                }

                applyLoadedSnapshot(snapshot)
                logger.log(
                    .ratesLoadSucceeded(
                        currencyDiscoverySource: snapshot.currencyDiscoverySource
                    )
                )
            } catch is CancellationError {
                guard isCurrentLoad(requestID) else {
                    return
                }

                setState(previousState)
            } catch {
                guard isCurrentLoad(requestID) else {
                    return
                }

                applyLoadFailure(using: previousState)
            }
        }

        loadTask = task
        return task
    }

    // MARK: - User Actions

    func updateAmount(_ rawText: String, field: InputField) {
        setState(stateReducer.amountUpdated(rawText: rawText, field: field, in: state))
    }

    func selectCurrency(_ currency: CurrencyCode) {
        guard !currency.isUSDc else {
            return
        }

        setState(stateReducer.currencySelected(currency, in: state))
    }

    func swapCurrencies() {
        setState(stateReducer.currenciesSwapped(in: state))
    }

    // MARK: - State Updates

    private func applyLoadedSnapshot(_ snapshot: ExchangeRatesSnapshot) {
        setState(
            stateReducer.loadedState(
                from: snapshot,
                previousState: state
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
        logger.log(.ratesLoadFailed)
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

    private func isCurrentLoad(_ requestID: Int) -> Bool {
        requestID == loadRequestID
    }

    deinit {
        loadTask?.cancel()
    }
}
