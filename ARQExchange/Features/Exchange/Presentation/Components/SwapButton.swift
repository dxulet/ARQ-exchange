import SwiftUI

struct SwapButtonLabel: View {
    var iconOpacity: CGFloat = 1
    var backgroundOpacity: CGFloat = 1

    var body: some View {
        Image(systemName: "arrow.down")
            .font(ExchangeDesign.Font.swapIcon)
            .foregroundStyle(.white.opacity(iconOpacity))
            .frame(width: ExchangeDesign.Layout.swapButtonSize, height: ExchangeDesign.Layout.swapButtonSize)
            .background(ExchangeDesign.Colors.brand.opacity(backgroundOpacity), in: Circle())
            .overlay(
                Circle()
                    .stroke(ExchangeDesign.Colors.background, lineWidth: ExchangeDesign.Layout.swapButtonBorderWidth)
            )
            .frame(width: ExchangeDesign.Layout.minimumHitTarget, height: ExchangeDesign.Layout.minimumHitTarget)
    }
}
