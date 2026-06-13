import Foundation

struct CurrencyCode: RawRepresentable, Identifiable, Equatable, Hashable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(apiCode: String) {
        let normalizedCode = apiCode.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedCode.lowercased() == Self.usdc.rawValue.lowercased() {
            rawValue = Self.usdc.rawValue
        } else {
            rawValue = normalizedCode.uppercased()
        }
    }

    var id: String { rawValue }

    var isUSDc: Bool {
        self == .usdc
    }

    static let usdc = CurrencyCode(rawValue: "USDc")
    static let mxn = CurrencyCode(rawValue: "MXN")
    static let ars = CurrencyCode(rawValue: "ARS")
    static let brl = CurrencyCode(rawValue: "BRL")
    static let cop = CurrencyCode(rawValue: "COP")

    static var localCurrencies: [CurrencyCode] {
        [.mxn, .ars, .brl, .cop]
    }
}
