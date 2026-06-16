import SwiftUI

@MainActor
struct ExchangeCalculatorLoadedView: View {
    let state: ExchangeCalculatorState
    let topAmountText: Binding<String>
    let bottomAmountText: Binding<String>
    let focusedField: FocusState<InputField?>.Binding
    let onSwapCurrencies: () -> Void
    let onPresentCurrencyPicker: () -> Void

    var body: some View {
        ZStack {
            ZStack(alignment: .top) {
                ForEach(currencies) { currency in
                    amountField(for: currency)
                }
            }
            .frame(height: rowsHeight, alignment: .top)

            Button(action: onSwapCurrencies) {
                SwapButtonLabel()
            }
            .buttonStyle(SwapButtonStyle())
            .accessibilityLabel(ExchangeCalculatorCopy.swapAccessibilityLabel)
            .disabled(state.loadState != .loaded)
        }
    }

    private var currencies: [CurrencyCode] {
        [state.topCurrency, state.bottomCurrency]
    }

    private var rowsHeight: CGFloat {
        ExchangeDesign.Layout.rowHeight * 2 + ExchangeDesign.Layout.rowSpacing
    }

    private func rowOffset(for field: InputField) -> CGFloat {
        switch field {
        case .top:
            0
        case .bottom:
            ExchangeDesign.Layout.rowHeight + ExchangeDesign.Layout.rowSpacing
        }
    }

    private func amountField(for currency: CurrencyCode) -> some View {
        let field = field(for: currency)

        return CurrencyAmountField(
            field: field,
            currency: currency,
            amountText: amountText(for: field),
            isCurrencySelectable: !currency.isUSDc,
            hasRate: state.currentRate != nil,
            focusedField: focusedField,
            onSelectCurrency: onPresentCurrencyPicker
        )
        .offset(y: rowOffset(for: field))
    }

    private func field(for currency: CurrencyCode) -> InputField {
        currency == state.topCurrency ? .top : .bottom
    }

    private func amountText(for field: InputField) -> Binding<String> {
        switch field {
        case .top:
            topAmountText
        case .bottom:
            bottomAmountText
        }
    }
}
