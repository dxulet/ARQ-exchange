#if DEBUG
import SwiftUI

// MARK: - ExchangeCalculatorScreenPreviews

@MainActor
struct ExchangeCalculatorScreenPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            screen(state: .loading)
                .previewDisplayName("Screen - loading")

            screen(state: .loadedFresh)
                .previewDisplayName("Screen - loaded fresh")

            screen(state: .loadFailed)
                .previewDisplayName("Screen - load failed")

            screen(state: .missingSelectedRate)
                .previewDisplayName("Screen - selected rate missing")

            screen(state: .topInputActive)
                .previewDisplayName("Screen - top input active")

            screen(state: .bottomInputActive)
                .previewDisplayName("Screen - bottom input active")

            screen(state: .swapped)
                .previewDisplayName("Screen - swapped")
        }
    }

    private static func screen(state: ExchangeCalculatorState) -> some View {
        ExchangeCalculatorView(
            viewModel: ExchangeCalculatorViewModel(
                ratesRepository: PreviewRatesRepository(),
                initialState: state
            )
        )
    }
}

// MARK: - ExchangeCalculatorComponentPreviews

@MainActor
struct ExchangeCalculatorComponentPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewCanvas {
                ExchangeCalculatorErrorView(
                    message: ExchangeCalculatorCopy.loadFailure,
                    onRetry: {}
                )
            }
            .previewDisplayName("Component - error")

            PreviewCanvas {
                LoadingCalculatorSkeleton(
                    topCurrency: .usdc,
                    bottomCurrency: .mxn
                )
            }
            .previewDisplayName("Component - loading skeleton")

            PreviewCanvas {
                LoadedViewPreview(state: .missingSelectedRate)
            }
            .previewDisplayName("Component - disabled rate")

            CurrencyPickerSheet(
                options: ExchangeCalculatorPreviewData.pickerItems,
                onSelectCurrency: { _ in }
            )
            .background(ExchangeDesign.Colors.background)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Component - picker availability")
        }
    }
}

// MARK: - PreviewCanvas

private struct PreviewCanvas<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ExchangeDesign.Colors.background
                .ignoresSafeArea()

            content
                .padding(.horizontal, 16)
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - LoadedViewPreview

@MainActor
private struct LoadedViewPreview: View {
    let state: ExchangeCalculatorState
    @State private var topAmountText: String
    @State private var bottomAmountText: String
    @FocusState private var focusedField: InputField?

    init(state: ExchangeCalculatorState) {
        self.state = state
        _topAmountText = State(initialValue: state.topAmountText)
        _bottomAmountText = State(initialValue: state.bottomAmountText)
    }

    var body: some View {
        ExchangeCalculatorLoadedView(
            state: state,
            topAmountText: $topAmountText,
            bottomAmountText: $bottomAmountText,
            focusedField: $focusedField,
            onSwapCurrencies: {},
            onPresentCurrencyPicker: {}
        )
    }
}

// MARK: - ExchangeCalculatorPreviewData

private enum ExchangeCalculatorPreviewData {
    static let fetchedAt = Date(timeIntervalSince1970: 1_780_000_000)

    static let mxnRate = ExchangeRate(
        base: .usdc,
        quote: .mxn,
        bid: decimal("18.4097"),
        ask: decimal("18.4410"),
        timestamp: "2026-06-10T12:35:55.356249099"
    )

    static let copRate = ExchangeRate(
        base: .usdc,
        quote: .cop,
        bid: decimal("3832.42"),
        ask: decimal("3890.83"),
        timestamp: "2026-06-10T12:35:55.356249099"
    )

    static let brlRate = ExchangeRate(
        base: .usdc,
        quote: .brl,
        bid: decimal("5.4312"),
        ask: decimal("5.4628"),
        timestamp: "2026-06-10T12:35:55.356249099"
    )

    static let ratesByCurrency: [CurrencyCode: ExchangeRate] = [
        .mxn: mxnRate,
        .cop: copRate,
        .brl: brlRate
    ]

    static let pickerItems: [CurrencyPickerItem] = CurrencyCode.localCurrencies.map { currency in
        CurrencyPickerItem(
            currency: currency,
            metadata: CurrencyMetadataCatalog.metadata(for: currency),
            isSelected: currency == .mxn,
            isSelectable: ratesByCurrency[currency] != nil
        )
    }

    static func loadedState(
        topCurrency: CurrencyCode = .usdc,
        bottomCurrency: CurrencyCode = .mxn,
        topAmountText: String = "",
        bottomAmountText: String = "",
        activeField: InputField? = nil,
        ratesByCurrency: [CurrencyCode: ExchangeRate] = ratesByCurrency
    ) -> ExchangeCalculatorState {
        ExchangeCalculatorState(
            loadState: .loaded,
            availableCurrencies: CurrencyCode.localCurrencies,
            ratesByCurrency: ratesByCurrency,
            topCurrency: topCurrency,
            bottomCurrency: bottomCurrency,
            topAmountText: topAmountText,
            bottomAmountText: bottomAmountText,
            activeField: activeField,
            isUsingStaleRates: false,
            ratesFetchedAt: fetchedAt
        )
    }

    static func decimal(_ value: String) -> Decimal {
        DecimalParser.apiDecimal(from: value) ?? 0
    }
}

// MARK: - ExchangeCalculatorState Preview States

private extension ExchangeCalculatorState {
    static var loading: ExchangeCalculatorState {
        var state = ExchangeCalculatorState()
        state.loadState = .loading
        return state
    }

    static var loadedFresh: ExchangeCalculatorState {
        ExchangeCalculatorPreviewData.loadedState()
    }

    static var loadFailed: ExchangeCalculatorState {
        var state = ExchangeCalculatorState()
        state.loadState = .failed(message: ExchangeCalculatorCopy.loadFailure)
        return state
    }

    static var missingSelectedRate: ExchangeCalculatorState {
        ExchangeCalculatorPreviewData.loadedState(
            ratesByCurrency: [.cop: ExchangeCalculatorPreviewData.copRate]
        )
    }

    static var topInputActive: ExchangeCalculatorState {
        ExchangeCalculatorPreviewData.loadedState(
            topAmountText: "1,000",
            bottomAmountText: "18,409.70",
            activeField: .top
        )
    }

    static var bottomInputActive: ExchangeCalculatorState {
        ExchangeCalculatorPreviewData.loadedState(
            topAmountText: "54.23",
            bottomAmountText: "1,000",
            activeField: .bottom
        )
    }

    static var swapped: ExchangeCalculatorState {
        ExchangeCalculatorPreviewData.loadedState(
            topCurrency: .mxn,
            bottomCurrency: .usdc,
            topAmountText: "18,441",
            bottomAmountText: "1,000",
            activeField: .bottom
        )
    }
}

// MARK: - PreviewRatesRepository

private actor PreviewRatesRepository: RatesRepository {
    func loadRatesSnapshot() async throws -> RatesRepositoryResult {
        RatesRepositoryResult(
            snapshot: ExchangeRatesSnapshot(
                availableCurrencies: CurrencyCode.localCurrencies,
                ratesByCurrency: ExchangeCalculatorPreviewData.ratesByCurrency,
                fetchedAt: ExchangeCalculatorPreviewData.fetchedAt
            ),
            source: .network
        )
    }
}
#endif
