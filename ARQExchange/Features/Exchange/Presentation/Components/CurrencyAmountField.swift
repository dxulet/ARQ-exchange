import SwiftUI

struct CurrencyAmountField: View {
    let field: InputField
    let currency: CurrencyCode
    @Binding var amountText: String
    let isCurrencySelectable: Bool
    let hasRate: Bool
    let focusedField: FocusState<InputField?>.Binding
    let onSelectCurrency: () -> Void

    private var metadata: CurrencyMetadata {
        CurrencyMetadataCatalog.metadata(for: currency)
    }

    var body: some View {
        HStack(spacing: 16) {
            currencyControl

            TextField(
                ExchangeCalculatorCopy.amountPlaceholder,
                text: $amountText
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .font(ExchangeDesign.Font.amount)
            .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
            .tint(ExchangeDesign.Colors.brand)
            .lineLimit(1)
            .minimumScaleFactor(ExchangeDesign.Layout.minimumScaleFactor)
            .disabled(!hasRate)
            .focused(focusedField, equals: field)
            .accessibilityLabel(ExchangeCalculatorCopy.amountAccessibilityLabel(for: currency))
        }
        .frame(height: ExchangeDesign.Layout.rowHeight)
        .padding(.horizontal, ExchangeDesign.Layout.rowHorizontalPadding)
        .background(ExchangeDesign.Colors.fieldBackground, in: RoundedRectangle(cornerRadius: ExchangeDesign.Layout.rowCornerRadius))
        .opacity(hasRate ? 1 : ExchangeDesign.Layout.unavailableOpacity)
    }

    @ViewBuilder
    private var currencyControl: some View {
        if isCurrencySelectable {
            Button(action: onSelectCurrency) {
                currencyLabel
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ExchangeCalculatorCopy.selectCurrencyAccessibilityLabel(for: currency))
        } else {
            currencyLabel
        }
    }

    private var currencyLabel: some View {
        HStack(spacing: 10) {
            CurrencyFlagView(metadata: metadata, size: ExchangeDesign.Layout.flagSize)

            Text(currency.rawValue)
                .font(ExchangeDesign.Font.body)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                .lineLimit(1)

            if isCurrencySelectable {
                Image(systemName: "chevron.down")
                    .font(ExchangeDesign.Font.chevron)
                    .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
            }
        }
        .fixedSize()
    }
}
