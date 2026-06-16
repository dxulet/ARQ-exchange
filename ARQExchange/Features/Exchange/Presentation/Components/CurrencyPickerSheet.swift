import SwiftUI

// MARK: - CurrencyPickerMetrics

private enum CurrencyPickerMetrics {
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 30
    static let contentSpacing: CGFloat = 16
    static let listBottomPadding: CGFloat = 16
    static let listVerticalPadding: CGFloat = 8
    static let listCornerRadius: CGFloat = 16
    static let closeButtonVisualSize: CGFloat = 32
    static let maximumListHeight: CGFloat = 420
    static let rowSpacing: CGFloat = 8
    static let rowHorizontalPadding: CGFloat = 16
    static let rowHeight: CGFloat = 62
    static let flagSize: CGFloat = 28
    static let flagContainerSize: CGFloat = 40
    static let selectionIndicatorSize: CGFloat = 24
    static let selectionIndicatorStrokeWidth: CGFloat = 2
    static let disabledOpacity: CGFloat = 0.45
}

// MARK: - CurrencyPickerSheetLayout

enum CurrencyPickerSheetLayout {
    static func preferredHeight(optionCount: Int) -> CGFloat {
        let sheetChromeHeight = CurrencyPickerMetrics.topPadding
            + CurrencyPickerMetrics.contentSpacing
            + ExchangeDesign.Layout.minimumHitTarget

        return sheetChromeHeight + listHeight(optionCount: optionCount)
    }

    static func listHeight(optionCount: Int) -> CGFloat {
        let rowContentHeight = CGFloat(optionCount) * CurrencyPickerMetrics.rowHeight
        let listPaddingHeight = CurrencyPickerMetrics.listBottomPadding
            + CurrencyPickerMetrics.listVerticalPadding * 2

        return min(
            rowContentHeight + listPaddingHeight,
            CurrencyPickerMetrics.maximumListHeight
        )
    }
}

// MARK: - CurrencyPickerSheet

@MainActor
struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let options: [CurrencyPickerItem]
    private let onSelectCurrency: (CurrencyCode) -> Void

    init(
        options: [CurrencyPickerItem],
        onSelectCurrency: @escaping (CurrencyCode) -> Void
    ) {
        self.options = options
        self.onSelectCurrency = onSelectCurrency
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CurrencyPickerMetrics.contentSpacing) {
            header
            currencyList
        }
        .padding(.top, CurrencyPickerMetrics.topPadding)
        .background(ExchangeDesign.Colors.background)
    }

    private var header: some View {
        HStack {
            Text(ExchangeCalculatorCopy.sheetTitle)
                .font(ExchangeDesign.Font.sheetTitle)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary)

            Spacer()

            Button(action: closeSheet) {
                Image(systemName: "xmark")
                    .font(ExchangeDesign.Font.closeIcon)
                    .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                    .frame(
                        width: CurrencyPickerMetrics.closeButtonVisualSize,
                        height: CurrencyPickerMetrics.closeButtonVisualSize
                    )
            }
            .frame(width: ExchangeDesign.Layout.minimumHitTarget, height: ExchangeDesign.Layout.minimumHitTarget)
            .buttonStyle(.plain)
            .accessibilityLabel(ExchangeCalculatorCopy.closeAccessibilityLabel)
        }
        .padding(.horizontal, CurrencyPickerMetrics.horizontalPadding)
    }

    private var currencyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(options) { option in
                    CurrencyPickerRow(
                        option: option,
                        onSelectCurrency: onSelectCurrency
                    )
                }
            }
            .padding(.vertical, CurrencyPickerMetrics.listVerticalPadding)
            .padding(.bottom, CurrencyPickerMetrics.listBottomPadding)
        }
        .frame(height: currencyListHeight)
        .scrollIndicators(.hidden)
        .background(
            ExchangeDesign.Colors.fieldBackground,
            in: RoundedRectangle(cornerRadius: CurrencyPickerMetrics.listCornerRadius)
        )
        .padding(.horizontal, CurrencyPickerMetrics.horizontalPadding)
    }

    private var currencyListHeight: CGFloat {
        CurrencyPickerSheetLayout.listHeight(optionCount: options.count)
    }

    private func closeSheet() {
        dismiss()
    }
}

// MARK: - CurrencyPickerRow

@MainActor
private struct CurrencyPickerRow: View {
    @Environment(\.dismiss) private var dismiss

    let option: CurrencyPickerItem
    let onSelectCurrency: (CurrencyCode) -> Void

    var body: some View {
        Button(action: selectCurrency) {
            HStack(spacing: CurrencyPickerMetrics.rowSpacing) {
                CurrencyFlagView(
                    currency: option.currency,
                    flag: option.flag,
                    size: CurrencyPickerMetrics.flagSize
                )
                    .frame(
                        width: CurrencyPickerMetrics.flagContainerSize,
                        height: CurrencyPickerMetrics.flagContainerSize
                    )

                Text(option.currency.rawValue)
                    .font(ExchangeDesign.Font.body)
                    .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                    .lineLimit(1)

                Spacer()

                selectionIndicator
            }
            .padding(.horizontal, CurrencyPickerMetrics.rowHorizontalPadding)
            .frame(maxWidth: .infinity, minHeight: CurrencyPickerMetrics.rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!option.isSelectable)
        .opacity(option.isSelectable ? 1 : CurrencyPickerMetrics.disabledOpacity)
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
                    lineWidth: CurrencyPickerMetrics.selectionIndicatorStrokeWidth
                )
                .frame(
                    width: CurrencyPickerMetrics.selectionIndicatorSize,
                    height: CurrencyPickerMetrics.selectionIndicatorSize
                )

            if isSelected {
                Circle()
                    .fill(ExchangeDesign.Colors.brand)
                    .frame(
                        width: CurrencyPickerMetrics.selectionIndicatorSize,
                        height: CurrencyPickerMetrics.selectionIndicatorSize
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
        dismiss()
    }
}
