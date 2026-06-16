import SwiftUI
import UIKit

// MARK: - CurrencyAmountField

@MainActor
struct CurrencyAmountField: View {
    let field: InputField
    let currency: CurrencyCode
    @Binding var amountText: String
    let isCurrencySelectable: Bool
    let hasRate: Bool
    let focusedField: FocusState<InputField?>.Binding
    let onSelectCurrency: () -> Void

    private var flag: ImageResource? {
        CurrencyFlagCatalog.flag(for: currency)
    }

    var body: some View {
        HStack(spacing: 16) {
            currencyControl

            FormattedAmountTextField(
                text: $amountText,
                placeholder: ExchangeCalculatorCopy.amountPlaceholder,
                isEnabled: hasRate,
                isFocused: focusedField.wrappedValue == field,
                onFocusChange: updateFocus
            )
            .accessibilityLabel(ExchangeCalculatorCopy.amountAccessibilityLabel(for: currency))
            .frame(height: ExchangeDesign.Layout.minimumHitTarget)
            .frame(maxWidth: .infinity)
            .clipped()
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
        HStack(spacing: ExchangeDesign.Layout.currencyLabelSpacing) {
            CurrencyFlagView(
                currency: currency,
                flag: flag,
                size: ExchangeDesign.Layout.flagSize
            )

            Text(currency.rawValue)
                .font(ExchangeDesign.Font.body)
                .tracking(ExchangeDesign.Tracking.body)
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

    private func updateFocus(isFocused: Bool) {
        if isFocused, focusedField.wrappedValue != field {
            focusedField.wrappedValue = field
        } else if focusedField.wrappedValue == field {
            focusedField.wrappedValue = nil
        }
    }
}

// MARK: - FormattedAmountTextField

private struct FormattedAmountTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isEnabled: Bool
    let isFocused: Bool
    let onFocusChange: (Bool) -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 13
        textField.clipsToBounds = true
        let textFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let textColor = UIColor(ExchangeDesign.Colors.contentPrimary)
        textField.font = textFont
        textField.textColor = textColor
        textField.defaultTextAttributes = [
            .font: textFont,
            .foregroundColor: textColor,
            .kern: ExchangeDesign.Tracking.body
        ]
        textField.textAlignment = .right
        textField.tintColor = UIColor(ExchangeDesign.Colors.brand)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        textField.placeholder = placeholder
        textField.isEnabled = isEnabled

        if textField.text != text {
            textField.text = text
            context.coordinator.moveCaretToEnd(in: textField)
        }

        switch context.coordinator.focusState.action(
            isEnabled: isEnabled,
            isFocused: isFocused,
            isFirstResponder: textField.isFirstResponder
        ) {
        case .none:
            break
        case .becomeFirstResponder:
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        case .resignFirstResponder:
            DispatchQueue.main.async {
                textField.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FormattedAmountTextField
        var focusState = FormattedAmountTextFieldFocusState()

        init(parent: FormattedAmountTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocusChange(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onFocusChange(false)
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let currentText = textField.text ?? ""

            guard let textRange = Range(range, in: currentText) else {
                return false
            }

            let proposedText = currentText.replacingCharacters(in: textRange, with: string)
            let formattedText = AmountFormatter.activeInputString(from: proposedText)
            parent.text = formattedText
            textField.text = formattedText
            moveCaretToEnd(in: textField)
            return false
        }

        func moveCaretToEnd(in textField: UITextField) {
            guard let endPosition = textField.position(from: textField.endOfDocument, offset: 0) else {
                return
            }

            textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
        }
    }
}

// MARK: - FormattedAmountTextFieldFocusState

struct FormattedAmountTextFieldFocusState {
    enum Action: Equatable {
        case none
        case becomeFirstResponder
        case resignFirstResponder
    }

    private var hasObservedFocusedState = false

    mutating func action(
        isEnabled: Bool,
        isFocused: Bool,
        isFirstResponder: Bool
    ) -> Action {
        guard isEnabled else {
            hasObservedFocusedState = false
            return isFirstResponder ? .resignFirstResponder : .none
        }

        if isFocused {
            hasObservedFocusedState = true
            return isFirstResponder ? .none : .becomeFirstResponder
        }

        guard hasObservedFocusedState else {
            return .none
        }

        guard isFirstResponder else {
            hasObservedFocusedState = false
            return .none
        }

        hasObservedFocusedState = false
        return .resignFirstResponder
    }
}
