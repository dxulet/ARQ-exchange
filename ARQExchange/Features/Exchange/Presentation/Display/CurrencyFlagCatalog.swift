import SwiftUI

enum CurrencyFlagCatalog {
    private static let knownFlags: [CurrencyCode: ImageResource] = [
        .usdc: .usFlag,
        .mxn: .mxFlag,
        .ars: .arFlag,
        .brl: .brFlag,
        .cop: .coFlag
    ]

    static func flag(for currency: CurrencyCode) -> ImageResource? {
        knownFlags[currency]
    }
}
