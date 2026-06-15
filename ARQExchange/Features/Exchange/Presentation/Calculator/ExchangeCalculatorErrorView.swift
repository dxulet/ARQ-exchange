import SwiftUI

private enum ExchangeCalculatorErrorMetrics {
    static let retryButtonHeight: CGFloat = 50
    static let retryButtonCornerRadius: CGFloat = 12
}

@MainActor
struct ExchangeCalculatorErrorView<ActionHandler: ExchangeCalculatorActionHandling>: View {
    let message: String
    let actionHandler: ActionHandler

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(message)
                .font(ExchangeDesign.Font.body)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary)

            Button(action: retryRatesLoad) {
                Text(ExchangeCalculatorCopy.retryTitle)
                    .font(ExchangeDesign.Font.body)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: ExchangeCalculatorErrorMetrics.retryButtonHeight)
                    .background(
                        ExchangeDesign.Colors.brand,
                        in: RoundedRectangle(cornerRadius: ExchangeCalculatorErrorMetrics.retryButtonCornerRadius)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ExchangeCalculatorCopy.retryAccessibilityLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func retryRatesLoad() {
        actionHandler.retryRatesLoad()
    }
}
