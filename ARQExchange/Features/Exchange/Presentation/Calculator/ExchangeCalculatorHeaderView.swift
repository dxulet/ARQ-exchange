import SwiftUI

struct ExchangeCalculatorHeaderView: View {
    let isLoading: Bool
    let rateText: String?

    private enum Metrics {
        static let bottomPadding: CGFloat = 24
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ExchangeCalculatorCopy.title)
                .font(ExchangeDesign.Font.title)
                .tracking(ExchangeDesign.Tracking.title)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                .lineLimit(1)
                .minimumScaleFactor(ExchangeDesign.Layout.minimumScaleFactor)

            Group {
                if isLoading {
                    LoadingSkeletonCapsule(width: 174, height: 12)
                } else if let rateText {
                    Text(rateText)
                        .font(ExchangeDesign.Font.rate)
                        .tracking(ExchangeDesign.Tracking.body)
                        .foregroundStyle(ExchangeDesign.Colors.brand)
                        .lineLimit(1)
                        .minimumScaleFactor(ExchangeDesign.Layout.minimumScaleFactor)
                }
            }
        }
        .padding(.bottom, Metrics.bottomPadding)
    }
}
