import SwiftUI

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

struct ExchangeFeatureDependencies: Sendable {
    let ratesRepository: RatesRepository
    let logger: ExchangeLogger
}

private struct CurrencyPickerPresentation: Identifiable, Equatable {
    let options: [CurrencyPickerItem]

    var id: String { "currency-picker" }
}

@MainActor
struct ExchangeCalculatorView: View {
    @ObservedObject private var viewModel: ExchangeCalculatorViewModel
    @State private var currencyPickerPresentation: CurrencyPickerPresentation?
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

    private var isAwaitingRates: Bool {
        switch viewModel.state.loadState {
        case .idle, .loading:
            return true
        case .loaded, .failed:
            return false
        }
    }

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
                            actionHandler: self
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
        .sheet(item: $currencyPickerPresentation) { presentation in
            CurrencyPickerSheet(
                options: presentation.options,
                selectionHandler: self
            )
            .presentationDetents([
                .height(CurrencyPickerSheetLayout.preferredHeight(optionCount: presentation.options.count))
            ])
            .presentationDragIndicator(.visible)
            .presentationBackground(ExchangeDesign.Colors.background)
        }
    }

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
                actionHandler: self
            )
        }
    }

    private func amountBinding(for field: InputField) -> Binding<String> {
        Binding(
            get: { viewModel.state.amountText(for: field) },
            set: { viewModel.updateAmount($0, field: field) }
        )
    }

    func presentCurrencyPicker() {
        guard currencyPickerPresentation == nil else {
            return
        }

        focusedAmountField = nil
        currencyPickerPresentation = CurrencyPickerPresentation(options: viewModel.state.currencyPickerItems)
    }
}

extension ExchangeCalculatorView: ExchangeCalculatorActionHandling {
    func retryRatesLoad() {
        viewModel.retry()
    }

    func swapCurrencies() {
        viewModel.swapCurrencies()
    }

    func selectCurrency(_ currency: CurrencyCode) {
        viewModel.selectCurrency(currency)
    }
}
