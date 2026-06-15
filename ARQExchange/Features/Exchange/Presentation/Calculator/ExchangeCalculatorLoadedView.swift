import SwiftUI

@MainActor
struct ExchangeCalculatorLoadedView<ActionHandler: ExchangeCalculatorActionHandling>: View {
    let state: ExchangeCalculatorState
    let topAmountText: Binding<String>
    let bottomAmountText: Binding<String>
    let focusedField: FocusState<InputField?>.Binding
    let actionHandler: ActionHandler

    var body: some View {
        ZStack {
            VStack(spacing: ExchangeDesign.Layout.rowSpacing) {
                amountField(for: .top, amountText: topAmountText)
                amountField(for: .bottom, amountText: bottomAmountText)
            }

            Button(action: swapCurrencies) {
                SwapButtonLabel()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ExchangeCalculatorCopy.swapAccessibilityLabel)
            .disabled(state.loadState != .loaded)
        }
    }

    private func amountField(for field: InputField, amountText: Binding<String>) -> some View {
        let currency = state.currency(for: field)

        return CurrencyAmountField(
            field: field,
            currency: currency,
            amountText: amountText,
            isCurrencySelectable: !currency.isUSDc,
            hasRate: state.currentRate != nil,
            focusedField: focusedField,
            currencyPickerPresenter: actionHandler
        )
    }

    private func swapCurrencies() {
        actionHandler.swapCurrencies()
    }
}
