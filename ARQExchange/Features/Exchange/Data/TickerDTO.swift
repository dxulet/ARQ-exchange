import Foundation

struct TickerDTO: Decodable, Equatable, Sendable {
    let ask: String
    let bid: String
    let currencyPairCode: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case ask
        case bid
        case currencyPairCode = "book"
        case timestamp = "date"
    }
}

enum TickerMappingError: Error, Equatable, Sendable {
    case invalidBook(String)
    case invalidDecimal(field: String, value: String)
    case nonPositiveDecimal(field: String, value: String)
    case unsupportedPair(String)
}

struct TickerMapper: Sendable {
    // MARK: - Public

    func makeExchangeRate(from tickerDTO: TickerDTO) throws -> ExchangeRate {
        let currencies = try currencyPair(from: tickerDTO.currencyPairCode)
        let decimalRates = try decimalRates(from: tickerDTO)

        guard currencies.base.isUSDc, !currencies.quote.isUSDc else {
            throw TickerMappingError.unsupportedPair(tickerDTO.currencyPairCode)
        }

        return ExchangeRate(
            base: currencies.base,
            quote: currencies.quote,
            bid: decimalRates.bid,
            ask: decimalRates.ask,
            timestamp: tickerDTO.timestamp
        )
    }

    // MARK: - Private

    private func currencyPair(from currencyPairCode: String) throws -> (base: CurrencyCode, quote: CurrencyCode) {
        let currencyCodes = currencyPairCode.split(separator: "_", omittingEmptySubsequences: false)

        guard currencyCodes.count == 2, currencyCodes.allSatisfy({ !$0.isEmpty }) else {
            throw TickerMappingError.invalidBook(currencyPairCode)
        }

        return (
            base: CurrencyCode(apiCode: String(currencyCodes[0])),
            quote: CurrencyCode(apiCode: String(currencyCodes[1]))
        )
    }

    private func decimalRates(from tickerDTO: TickerDTO) throws -> (bid: Decimal, ask: Decimal) {
        let askRate = try positiveDecimal(from: tickerDTO.ask, field: "ask")
        let bidRate = try positiveDecimal(from: tickerDTO.bid, field: "bid")

        return (bid: bidRate, ask: askRate)
    }

    private func positiveDecimal(from text: String, field: String) throws -> Decimal {
        guard let decimal = DecimalParser.apiDecimal(from: text) else {
            throw TickerMappingError.invalidDecimal(field: field, value: text)
        }

        guard decimal > 0 else {
            throw TickerMappingError.nonPositiveDecimal(field: field, value: text)
        }

        return decimal
    }
}
