import Foundation

enum InputSanitizer {
    static func sanitize(_ rawInput: String) -> String {
        var result = ""
        var hasDecimalSeparator = false

        for character in rawInput {
            if character.isNumber {
                result.append(character)
            } else if character == ".", !hasDecimalSeparator {
                result.append(character)
                hasDecimalSeparator = true
            }
        }

        return result
    }
}

enum DecimalParser {
    private static let stableLocale = Locale(identifier: "en_US_POSIX")

    static func apiDecimal(from text: String) -> Decimal? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let decimalPattern = #"^[+-]?[0-9]+(\.[0-9]+)?$"#

        guard
            trimmedText.range(of: decimalPattern, options: .regularExpression) != nil
        else {
            return nil
        }

        return Decimal(string: trimmedText, locale: stableLocale)
    }

    static func userInputDecimal(from text: String) -> Decimal? {
        Decimal(string: InputSanitizer.sanitize(text), locale: stableLocale)
    }
}
