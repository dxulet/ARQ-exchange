import SwiftUI

struct SwapButtonLabel: View {
    var body: some View {
        Image(systemName: "arrow.down")
            .font(ExchangeDesign.Font.swapIcon)
            .foregroundStyle(.white)
            .frame(width: ExchangeDesign.Layout.swapButtonSize, height: ExchangeDesign.Layout.swapButtonSize)
            .background(ExchangeDesign.Colors.brand, in: Circle())
            .overlay(
                Circle()
                    .stroke(ExchangeDesign.Colors.background, lineWidth: ExchangeDesign.Layout.swapButtonBorderWidth)
            )
    }
}
