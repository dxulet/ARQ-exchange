import SwiftUI

@MainActor
struct ExchangeFeatureView: View {
    @StateObject private var viewModel: ExchangeCalculatorViewModel

    init(dependencies: ExchangeFeatureDependencies) {
        _viewModel = StateObject(
            wrappedValue: ExchangeCalculatorViewModel(
                loadingUseCase: RatesLoadingUseCase(ratesRepository: dependencies.ratesRepository),
                analyticsClient: dependencies.analyticsClient
            )
        )
    }

    var body: some View {
        ExchangeCalculatorView(viewModel: viewModel)
    }
}

struct ExchangeFeatureDependencies: Sendable {
    let ratesRepository: RatesRepository
    let analyticsClient: AnalyticsClient
}

private struct CurrencyPickerPresentation: Identifiable, Equatable {
    let options: [CurrencyPickerOption]

    var id: String { "currency-picker" }
}

@MainActor
struct ExchangeCalculatorView: View {
    @ObservedObject private var viewModel: ExchangeCalculatorViewModel
    @State private var currencyPickerPresentation: CurrencyPickerPresentation?
    @FocusState private var focusedAmountField: InputField?

    init(viewModel: ExchangeCalculatorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            ExchangeDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    switch viewModel.state.loadState {
                    case .failed(let message):
                        errorView(message: message)
                    default:
                        calculator
                    }
                }
                .frame(maxWidth: ExchangeDesign.Layout.contentMaxWidth, alignment: .leading)
                .padding(.horizontal, ExchangeDesign.Layout.horizontalPadding)
                .padding(.top, ExchangeDesign.Layout.titleTopPadding)
                .padding(.bottom, ExchangeDesign.Layout.bottomPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .sheet(item: $currencyPickerPresentation) { presentation in
            CurrencyPickerSheet(
                options: presentation.options,
                onSelectCurrency: selectCurrency
            )
            .presentationDetents([
                .height(CurrencyPickerSheet.preferredHeight(optionCount: presentation.options.count))
            ])
            .presentationDragIndicator(.visible)
            .presentationBackground(ExchangeDesign.Colors.background)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ExchangeCalculatorCopy.title)
                .font(ExchangeDesign.Font.title)
                .tracking(ExchangeDesign.Font.titleTracking)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                .lineLimit(1)
                .minimumScaleFactor(ExchangeDesign.Layout.minimumScaleFactor)
                .frame(height: ExchangeDesign.Font.titleLineHeight, alignment: .leading)

            Group {
                if viewModel.state.loadState == .loading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(viewModel.rateText)
                        .font(ExchangeDesign.Font.rate)
                        .foregroundStyle(ExchangeDesign.Colors.brand)
                        .lineLimit(1)
                        .minimumScaleFactor(ExchangeDesign.Layout.minimumScaleFactor)
                }
            }
            .frame(height: ExchangeDesign.Layout.headerRateHeight, alignment: .leading)
        }
        .padding(.bottom, ExchangeDesign.Layout.headerBottomPadding)
    }

    private var calculator: some View {
        ZStack {
            VStack(spacing: ExchangeDesign.Layout.rowSpacing) {
                amountField(for: .top)
                amountField(for: .bottom)
            }

            Button(action: viewModel.swapCurrencies) {
                SwapButtonLabel()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ExchangeCalculatorCopy.swapAccessibilityLabel)
            .disabled(viewModel.state.loadState != .loaded)
        }
    }

    private func amountField(for field: InputField) -> some View {
        let currency = viewModel.state.currency(for: field)

        return CurrencyAmountField(
            field: field,
            currency: currency,
            amountText: amountBinding(for: field),
            isCurrencySelectable: !currency.isUSDc,
            hasRate: viewModel.state.currentRate != nil,
            focusedField: $focusedAmountField,
            onSelectCurrency: presentCurrencyPicker
        )
    }

    private func amountBinding(for field: InputField) -> Binding<String> {
        Binding(
            get: { viewModel.state.amountText(for: field) },
            set: { viewModel.updateAmount($0, field: field) }
        )
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(message)
                .font(ExchangeDesign.Font.body)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary)

            Button {
                Task {
                    await viewModel.retry()
                }
            } label: {
                Text(ExchangeCalculatorCopy.retryTitle)
                    .font(ExchangeDesign.Font.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: ExchangeDesign.Layout.retryButtonHeight)
                    .background(
                        ExchangeDesign.Colors.brand,
                        in: RoundedRectangle(cornerRadius: ExchangeDesign.Layout.retryButtonCornerRadius)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ExchangeCalculatorCopy.retryAccessibilityLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func selectCurrency(_ currency: CurrencyCode) {
        viewModel.selectCurrency(currency)
    }

    private func presentCurrencyPicker() {
        guard currencyPickerPresentation == nil else {
            return
        }

        focusedAmountField = nil
        currencyPickerPresentation = CurrencyPickerPresentation(options: viewModel.state.currencyPickerOptions)
    }
}
