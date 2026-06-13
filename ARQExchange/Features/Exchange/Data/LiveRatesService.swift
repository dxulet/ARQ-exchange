struct LiveRatesService: RatesService {
    private let client: APIClientSending
    private let tickerMapper: TickerMapper
    private let diagnostics: RatesDiagnostics

    init(
        client: APIClientSending,
        tickerMapper: TickerMapper = TickerMapper(),
        diagnostics: RatesDiagnostics = NoopRatesDiagnostics()
    ) {
        self.client = client
        self.tickerMapper = tickerMapper
        self.diagnostics = diagnostics
    }

    func fetchAvailableCurrencies() async throws -> CurrencyDiscoveryResult {
        do {
            let currencyCodeResponse = try await client.send(.tickerCurrencies, as: [String].self)
            let currencies = localCurrencies(from: currencyCodeResponse.map(CurrencyCode.init(apiCode:)))

            guard !currencies.isEmpty else {
                diagnostics.record(.currencyDiscoveryFallback(source: .fallbackEmpty))
                return CurrencyDiscoveryResult(currencies: CurrencyCode.localCurrencies, source: .fallbackEmpty)
            }

            return CurrencyDiscoveryResult(currencies: currencies, source: .remote)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnostics.record(.currencyDiscoveryFallback(source: .fallbackError))
            return CurrencyDiscoveryResult(currencies: CurrencyCode.localCurrencies, source: .fallbackError)
        }
    }

    func fetchRates(for currencies: [CurrencyCode]) async throws -> [ExchangeRate] {
        let requestedCurrencies = localCurrencies(from: currencies)

        guard !requestedCurrencies.isEmpty else {
            return []
        }

        let tickerResponses = try await client.send(.tickers(currencies: requestedCurrencies), as: [TickerResponse].self)
        var rates: [ExchangeRate] = []

        for response in tickerResponses {
            do {
                rates.append(try tickerMapper.makeExchangeRate(from: response))
            } catch {
                diagnostics.record(
                    .tickerMappingSkipped(
                        book: response.currencyPairCode,
                        reason: String(describing: error)
                    )
                )
            }
        }

        return rates
    }

    private func localCurrencies(from currencies: [CurrencyCode]) -> [CurrencyCode] {
        var seenCurrencies = Set<CurrencyCode>()
        return currencies.filter { currency in
            !currency.isUSDc && seenCurrencies.insert(currency).inserted
        }
    }
}
