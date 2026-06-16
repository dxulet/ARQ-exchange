import SwiftUI

struct CurrencyFlagView: View {
    let metadata: CurrencyMetadata
    let size: CGFloat

    var body: some View {
        Group {
            if let flag = metadata.flag {
                Image(flag)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(String(metadata.code.rawValue.prefix(2)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ExchangeDesign.Colors.contentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ExchangeDesign.Colors.separator)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
