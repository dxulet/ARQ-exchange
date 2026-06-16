import Foundation

enum DisplayNumberFormatter {
    private static let amountFormatter: NumberFormatter = {
        let formatter = makeDecimalFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let rateFormatter: NumberFormatter = {
        let formatter = makeDecimalFormatter()
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 1
        formatter.maximumSignificantDigits = 6
        return formatter
    }()

    static func amountString(from value: Decimal) -> String {
        amountFormatter.string(from: value as NSDecimalNumber) ?? "0"
    }

    static func rateString(from value: Decimal) -> String {
        rateFormatter.string(from: value as NSDecimalNumber) ?? "0"
    }

    private static func makeDecimalFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter
    }
}

enum AmountFormatter {
    static func string(from value: Decimal) -> String {
        DisplayNumberFormatter.amountString(from: value)
    }

    static func activeInputString(from rawInput: String) -> String {
        let sanitizedInput = InputSanitizer.sanitize(rawInput)

        guard !sanitizedInput.isEmpty else {
            return ""
        }

        let parts = sanitizedInput.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let wholePart = normalizedWholePart(String(parts.first ?? ""))
        let formattedWholePart = groupedWholePart(wholePart)

        guard parts.count == 2 else {
            return formattedWholePart
        }

        return "\(formattedWholePart).\(parts[1])"
    }

    private static func normalizedWholePart(_ wholePart: String) -> String {
        let normalized = wholePart.drop { $0 == "0" }
        return normalized.isEmpty ? "0" : String(normalized)
    }

    private static func groupedWholePart(_ wholePart: String) -> String {
        var grouped = ""

        for (index, character) in wholePart.reversed().enumerated() {
            if index > 0, index.isMultiple(of: 3) {
                grouped.append(",")
            }

            grouped.append(character)
        }

        return String(grouped.reversed())
    }
}
