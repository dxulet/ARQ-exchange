import SwiftUI

// MARK: - ExchangeFeatureView

@MainActor
struct ExchangeFeatureView: View {
    @StateObject private var viewModel: ExchangeCalculatorViewModel

    init(dependencies: ExchangeFeatureDependencies) {
        _viewModel = StateObject(
            wrappedValue: ExchangeCalculatorViewModel(
                ratesRepository: dependencies.ratesRepository,
                logger: dependencies.logger
            )
        )
    }

    var body: some View {
        ExchangeCalculatorView(viewModel: viewModel)
    }
}

// MARK: - ExchangeFeatureDependencies

struct ExchangeFeatureDependencies: Sendable {
    let ratesRepository: RatesRepository
    let logger: ExchangeLogger
}

// MARK: - ExchangeCalculatorView

@MainActor
struct ExchangeCalculatorView: View {
    @ObservedObject private var viewModel: ExchangeCalculatorViewModel
    @State private var isCurrencyPickerPresented = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedAmountField: InputField?

    private enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 64
        static let bottomPadding: CGFloat = 32
        static let contentMaxWidth: CGFloat = 375
    }

    init(viewModel: ExchangeCalculatorViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Derived State

    private var isAwaitingRates: Bool {
        switch viewModel.state.loadState {
        case .idle, .loading:
            return true
        case .loaded, .failed:
            return false
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ExchangeDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ExchangeCalculatorHeaderView(
                        isLoading: isAwaitingRates,
                        rateText: viewModel.rateText
                    )

                    switch viewModel.state.loadState {
                    case .failed(let message):
                        ExchangeCalculatorErrorView(
                            message: message,
                            onRetry: retryRatesLoad
                        )
                    default:
                        calculator
                    }
                }
                .frame(maxWidth: Metrics.contentMaxWidth, alignment: .leading)
                .padding(.horizontal, Metrics.horizontalPadding)
                .padding(.top, Metrics.titleTopPadding)
                .padding(.bottom, Metrics.bottomPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        }
        .task {
            _ = viewModel.loadIfNeeded()
        }
        .sheet(isPresented: $isCurrencyPickerPresented) {
            let currencyPickerItems = viewModel.currencyPickerItems

            CurrencyPickerSheet(
                options: currencyPickerItems,
                onSelectCurrency: selectCurrency
            )
            .presentationDetents([
                .height(
                    CurrencyPickerSheetLayout.preferredHeight(optionCount: currencyPickerItems.count)
                )
            ])
            .presentationDragIndicator(.visible)
            .presentationBackground(ExchangeDesign.Colors.background)
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var calculator: some View {
        if isAwaitingRates {
            LoadingCalculatorSkeleton(
                topCurrency: viewModel.state.topCurrency,
                bottomCurrency: viewModel.state.bottomCurrency
            )
        } else {
            ExchangeCalculatorLoadedView(
                state: viewModel.state,
                topAmountText: amountBinding(for: .top),
                bottomAmountText: amountBinding(for: .bottom),
                focusedField: $focusedAmountField,
                onSwapCurrencies: swapCurrencies,
                onPresentCurrencyPicker: presentCurrencyPicker
            )
        }
    }

    private func amountBinding(for field: InputField) -> Binding<String> {
        Binding(
            get: { viewModel.state.amountText(for: field) },
            set: { rawText in
                if focusedAmountField != field {
                    focusedAmountField = field
                }
                viewModel.updateAmount(rawText, field: field)
            }
        )
    }

    private func retryRatesLoad() {
        viewModel.retry()
    }

    private func swapCurrencies() {
        let shouldRestoreFocus = focusedAmountField != nil

        withAnimation(reduceMotion ? nil : .interactiveSpring(response: 0.28, dampingFraction: 0.86, blendDuration: 0)) {
            viewModel.swapCurrencies()
        }

        if shouldRestoreFocus {
            focusedAmountField = viewModel.state.activeField
        }
    }

    private func presentCurrencyPicker() {
        guard !isCurrencyPickerPresented else {
            return
        }

        focusedAmountField = nil
        isCurrencyPickerPresented = true
    }

    private func selectCurrency(_ currency: CurrencyCode) {
        viewModel.selectCurrency(currency)
    }
}
