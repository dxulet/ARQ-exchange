import Foundation

enum DisplayNumberFormatter {
    static func amountString(from value: Decimal) -> String {
        decimal(maximumFractionDigits: 2).string(from: value as NSDecimalNumber) ?? "0"
    }

    static func rateString(from value: Decimal) -> String {
        decimal(maximumFractionDigits: 4).string(from: value as NSDecimalNumber) ?? "0"
    }

    private static func decimal(maximumFractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.usesGroupingSeparator = true
        return formatter
    }
}

enum AmountFormatter {
    static func string(from value: Decimal) -> String {
        DisplayNumberFormatter.amountString(from: value)
    }
}
