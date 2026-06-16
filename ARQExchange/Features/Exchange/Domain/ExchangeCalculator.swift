import Foundation

struct ConversionRequest: Equatable, Sendable {
    let amount: Decimal
    let sourceCurrency: CurrencyCode
    let targetCurrency: CurrencyCode
    let rate: ExchangeRate
    let quoteSide: QuoteSide
}

enum ExchangeCalculationError: Error, Equatable, Sendable {
    case unsupportedBase(CurrencyCode)
    case nonPositiveRate
    case unsupportedPair(source: CurrencyCode, target: CurrencyCode)
}

struct ExchangeCalculator: Sendable {
    func convert(_ request: ConversionRequest) throws -> Decimal {
        guard request.rate.base.isUSDc else {
            throw ExchangeCalculationError.unsupportedBase(request.rate.base)
        }

        let quoteRate = quoteRate(from: request.rate, side: request.quoteSide)

        guard quoteRate > 0 else {
            throw ExchangeCalculationError.nonPositiveRate
        }

        if request.sourceCurrency == request.rate.base, request.targetCurrency == request.rate.quote {
            return request.amount * quoteRate
        }

        if request.sourceCurrency == request.rate.quote, request.targetCurrency == request.rate.base {
            return request.amount / quoteRate
        }

        throw ExchangeCalculationError.unsupportedPair(
            source: request.sourceCurrency,
            target: request.targetCurrency
        )
    }

    private func quoteRate(from rate: ExchangeRate, side: QuoteSide) -> Decimal {
        switch side {
        case .bid:
            return rate.bid
        case .ask:
            return rate.ask
        }
    }
}
