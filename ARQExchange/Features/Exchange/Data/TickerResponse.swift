import Foundation

struct TickerResponse: Decodable, Equatable, Sendable {
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
    case unsupportedPair(String)
}

struct TickerMapper: Sendable {
    func makeExchangeRate(from response: TickerResponse) throws -> ExchangeRate {
        let currencies = try currencyPair(from: response.currencyPairCode)
        let decimalRates = try decimalRates(from: response)

        guard currencies.base.isUSDc, !currencies.quote.isUSDc else {
            throw TickerMappingError.unsupportedPair(response.currencyPairCode)
        }

        return ExchangeRate(
            base: currencies.base,
            quote: currencies.quote,
            bid: decimalRates.bid,
            ask: decimalRates.ask,
            timestamp: response.timestamp
        )
    }

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

    private func decimalRates(from response: TickerResponse) throws -> (bid: Decimal, ask: Decimal) {
        guard let askRate = DecimalParser.apiDecimal(from: response.ask) else {
            throw TickerMappingError.invalidDecimal(field: "ask", value: response.ask)
        }

        guard let bidRate = DecimalParser.apiDecimal(from: response.bid) else {
            throw TickerMappingError.invalidDecimal(field: "bid", value: response.bid)
        }

        return (bid: bidRate, ask: askRate)
    }
}
