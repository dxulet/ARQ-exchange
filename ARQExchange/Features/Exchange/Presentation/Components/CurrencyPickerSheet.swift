import SwiftUI

struct CurrencyPickerOption: Identifiable, Equatable, Sendable {
    let currency: CurrencyCode
    let metadata: CurrencyMetadata
    let isSelected: Bool
    let isSelectable: Bool

    var id: String {
        currency.id
    }
}

struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let orderedOptions: [CurrencyPickerOption]
    let onSelectCurrency: (CurrencyCode) -> Void

    private static let pickerOrder: [CurrencyCode] = [.ars, .cop, .mxn, .brl]
    private static let pickerOrderRanks: [CurrencyCode: Int] = Dictionary(
        uniqueKeysWithValues: pickerOrder.enumerated().map { index, currency in
            (currency, index)
        }
    )

    init(
        options: [CurrencyPickerOption],
        onSelectCurrency: @escaping (CurrencyCode) -> Void
    ) {
        orderedOptions = Self.orderedOptions(from: options)
        self.onSelectCurrency = onSelectCurrency
    }

    static func preferredHeight(optionCount: Int) -> CGFloat {
        let rowContentHeight = CGFloat(optionCount) * ExchangeDesign.Layout.pickerRowHeight
        let sheetChromeHeight = ExchangeDesign.Layout.sheetTopPadding
            + ExchangeDesign.Layout.sheetContentSpacing
            + ExchangeDesign.Layout.closeButtonSize
        let listPaddingHeight = ExchangeDesign.Layout.sheetListBottomPadding
            + ExchangeDesign.Layout.sheetListVerticalPadding * 2

        return sheetChromeHeight + rowContentHeight + listPaddingHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ExchangeDesign.Layout.sheetContentSpacing) {
            header
            currencyList
        }
        .padding(.top, ExchangeDesign.Layout.sheetTopPadding)
        .background(ExchangeDesign.Colors.background)
    }

    private var header: some View {
        HStack {
            Text(ExchangeCalculatorCopy.sheetTitle)
                .font(ExchangeDesign.Font.sheetTitle)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(ExchangeDesign.Font.closeIcon)
                    .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                    .frame(
                        width: ExchangeDesign.Layout.closeButtonSize,
                        height: ExchangeDesign.Layout.closeButtonSize
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ExchangeCalculatorCopy.closeAccessibilityLabel)
        }
        .padding(.horizontal, ExchangeDesign.Layout.sheetHorizontalPadding)
    }

    private var currencyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(orderedOptions) { option in
                    CurrencyPickerRow(
                        option: option,
                        onSelectCurrency: selectCurrency
                    )
                }
            }
            .padding(.vertical, ExchangeDesign.Layout.sheetListVerticalPadding)
            .padding(.bottom, ExchangeDesign.Layout.sheetListBottomPadding)
        }
        .frame(height: currencyListHeight)
        .scrollIndicators(.hidden)
        .background(
            ExchangeDesign.Colors.fieldBackground,
            in: RoundedRectangle(cornerRadius: ExchangeDesign.Layout.sheetListCornerRadius)
        )
        .padding(.horizontal, ExchangeDesign.Layout.sheetHorizontalPadding)
    }

    private static func orderedOptions(from options: [CurrencyPickerOption]) -> [CurrencyPickerOption] {
        options.enumerated()
            .sorted { left, right in
                let leftRank = Self.pickerOrderRanks[left.element.currency] ?? Int.max
                let rightRank = Self.pickerOrderRanks[right.element.currency] ?? Int.max

                if leftRank != rightRank {
                    return leftRank < rightRank
                }

                return left.offset < right.offset
            }
            .map(\.element)
    }

    private var currencyListHeight: CGFloat {
        CGFloat(orderedOptions.count) * ExchangeDesign.Layout.pickerRowHeight
            + ExchangeDesign.Layout.sheetListVerticalPadding * 2
            + ExchangeDesign.Layout.sheetListBottomPadding
    }

    private func selectCurrency(_ currency: CurrencyCode) {
        onSelectCurrency(currency)
        dismiss()
    }
}

private struct CurrencyPickerRow: View {
    let option: CurrencyPickerOption
    let onSelectCurrency: (CurrencyCode) -> Void

    var body: some View {
        Button(action: selectCurrency) {
            HStack(spacing: ExchangeDesign.Layout.pickerRowSpacing) {
                CurrencyFlagView(metadata: option.metadata, size: ExchangeDesign.Layout.pickerFlagSize)
                    .frame(
                        width: ExchangeDesign.Layout.pickerFlagContainerSize,
                        height: ExchangeDesign.Layout.pickerFlagContainerSize
                    )
                    .background(
                        ExchangeDesign.Colors.background,
                        in: RoundedRectangle(cornerRadius: ExchangeDesign.Layout.pickerFlagContainerCornerRadius)
                    )

                Text(option.currency.rawValue)
                    .font(ExchangeDesign.Font.body)
                    .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                    .lineLimit(1)

                Spacer()

                selectionIndicator
            }
            .padding(.horizontal, ExchangeDesign.Layout.pickerRowHorizontalPadding)
            .frame(height: ExchangeDesign.Layout.pickerRowHeight)
        }
        .buttonStyle(.plain)
        .disabled(!option.isSelectable)
        .opacity(option.isSelectable ? 1 : ExchangeDesign.Layout.disabledCurrencyOpacity)
        .accessibilityLabel(ExchangeCalculatorCopy.selectCurrencyAccessibilityLabel(for: option.currency))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var isSelected: Bool {
        option.isSelected
    }

    private var accessibilityValue: String {
        if !option.isSelectable {
            return ExchangeCalculatorCopy.unavailableCurrencyAccessibilityValue(for: option.currency)
        }

        return isSelected ? ExchangeCalculatorCopy.selectedCurrencyAccessibilityValue(for: option.currency) : ""
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected ? ExchangeDesign.Colors.brand : ExchangeDesign.Colors.separator,
                    lineWidth: ExchangeDesign.Layout.selectionIndicatorStrokeWidth
                )
                .frame(
                    width: ExchangeDesign.Layout.selectionIndicatorSize,
                    height: ExchangeDesign.Layout.selectionIndicatorSize
                )

            if isSelected {
                Circle()
                    .fill(ExchangeDesign.Colors.brand)
                    .frame(
                        width: ExchangeDesign.Layout.selectionIndicatorSize,
                        height: ExchangeDesign.Layout.selectionIndicatorSize
                    )

                Image(systemName: "checkmark")
                    .font(ExchangeDesign.Font.checkmark)
                    .foregroundStyle(.white)
            }
        }
        .accessibilityHidden(true)
    }

    private func selectCurrency() {
        onSelectCurrency(option.currency)
    }
}
