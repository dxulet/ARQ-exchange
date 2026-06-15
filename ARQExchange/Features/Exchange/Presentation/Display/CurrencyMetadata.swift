struct CurrencyMetadata: Identifiable, Equatable, Sendable {
    let code: CurrencyCode
    let displayName: String
    let flagAssetName: String?

    var id: String { code.id }
}

enum CurrencyMetadataCatalog {
    private static let knownMetadata: [CurrencyCode: CurrencyMetadata] = [
        .usdc: CurrencyMetadata(code: .usdc, displayName: "USD Coin", flagAssetName: "us_flag"),
        .mxn: CurrencyMetadata(code: .mxn, displayName: "Mexican Peso", flagAssetName: "mx_flag"),
        .ars: CurrencyMetadata(code: .ars, displayName: "Argentine Peso", flagAssetName: "ar_flag"),
        .brl: CurrencyMetadata(code: .brl, displayName: "Brazilian Real", flagAssetName: "br_flag"),
        .cop: CurrencyMetadata(code: .cop, displayName: "Colombian Peso", flagAssetName: "co_flag")
    ]

    static func metadata(for currency: CurrencyCode) -> CurrencyMetadata {
        knownMetadata[currency] ?? CurrencyMetadata(
            code: currency,
            displayName: currency.rawValue,
            flagAssetName: nil
        )
    }
}
