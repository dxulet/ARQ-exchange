import SwiftUI

struct LoadingCalculatorSkeleton: View {
    let topCurrency: CurrencyCode
    let bottomCurrency: CurrencyCode

    var body: some View {
        ZStack {
            VStack(spacing: ExchangeDesign.Layout.rowSpacing) {
                LoadingAmountRow(currency: topCurrency, showsChevron: !topCurrency.isUSDc)
                LoadingAmountRow(currency: bottomCurrency, showsChevron: !bottomCurrency.isUSDc)
            }

            LoadingSwapButton()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ExchangeCalculatorCopy.loadingAccessibilityLabel)
    }
}

private struct LoadingAmountRow: View {
    let currency: CurrencyCode
    let showsChevron: Bool

    private var metadata: CurrencyMetadata {
        CurrencyMetadataCatalog.metadata(for: currency)
    }

    var body: some View {
        HStack(spacing: 16) {
            currencyLabel

            Spacer(minLength: 12)

            LoadingSkeletonCapsule(width: 96, height: 14)
        }
        .frame(minHeight: ExchangeDesign.Layout.rowHeight)
        .padding(.horizontal, ExchangeDesign.Layout.rowHorizontalPadding)
        .background(
            ExchangeDesign.Colors.fieldBackground,
            in: RoundedRectangle(cornerRadius: ExchangeDesign.Layout.rowCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: ExchangeDesign.Layout.rowCornerRadius)
                .stroke(ExchangeDesign.Colors.separator.opacity(0.35), lineWidth: 1)
        }
    }

    private var currencyLabel: some View {
        HStack(spacing: ExchangeDesign.Layout.currencyLabelSpacing) {
            CurrencyFlagView(metadata: metadata, size: ExchangeDesign.Layout.flagSize)
                .opacity(0.45)

            Text(currency.rawValue)
                .font(ExchangeDesign.Font.body)
                .foregroundStyle(ExchangeDesign.Colors.contentPrimary.opacity(0.38))
                .lineLimit(1)

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(ExchangeDesign.Font.chevron)
                    .foregroundStyle(ExchangeDesign.Colors.contentPrimary.opacity(0.3))
            }
        }
        .fixedSize()
        .accessibilityHidden(true)
    }
}

private struct LoadingSwapButton: View {
    var body: some View {
        SwapButtonLabel(iconOpacity: 0.7, backgroundOpacity: 0.35)
        .accessibilityHidden(true)
    }
}

struct LoadingSkeletonCapsule: View {
    let width: CGFloat
    let height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(ExchangeDesign.Colors.separator.opacity(0.42))
            .frame(width: width, height: height)
            .overlay {
                if !reduceMotion {
                    shimmer
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: height / 2, style: .continuous))
            .onAppear {
                guard !reduceMotion else {
                    return
                }

                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1
                }
            }
            .accessibilityHidden(true)
    }

    private var shimmer: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.65),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.75, height: proxy.size.height)
            .offset(x: shimmerOffset * proxy.size.width)
        }
        .allowsHitTesting(false)
    }
}
