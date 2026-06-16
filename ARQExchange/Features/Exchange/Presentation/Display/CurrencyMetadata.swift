import SwiftUI

struct CurrencyMetadata: Identifiable, Equatable, Sendable {
    let code: CurrencyCode
    let displayName: String
    let flag: ImageResource?

    var id: String { code.id }
}

enum CurrencyMetadataCatalog {
    private static let knownMetadata: [CurrencyCode: CurrencyMetadata] = [
        .usdc: CurrencyMetadata(code: .usdc, displayName: "USD Coin", flag: .usFlag),
        .mxn: CurrencyMetadata(code: .mxn, displayName: "Mexican Peso", flag: .mxFlag),
        .ars: CurrencyMetadata(code: .ars, displayName: "Argentine Peso", flag: .arFlag),
        .brl: CurrencyMetadata(code: .brl, displayName: "Brazilian Real", flag: .brFlag),
        .cop: CurrencyMetadata(code: .cop, displayName: "Colombian Peso", flag: .coFlag)
    ]

    static func metadata(for currency: CurrencyCode) -> CurrencyMetadata {
        knownMetadata[currency] ?? CurrencyMetadata(
            code: currency,
            displayName: currency.rawValue,
            flag: nil
        )
    }
}
