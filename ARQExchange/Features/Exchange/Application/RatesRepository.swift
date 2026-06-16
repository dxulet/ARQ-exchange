protocol RatesRepository: Sendable {
    func loadRatesSnapshot() async throws -> ExchangeRatesSnapshot
}
