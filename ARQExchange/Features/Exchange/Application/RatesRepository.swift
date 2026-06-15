enum RatesSnapshotSource: String, Equatable, Sendable {
    case network
    case staleCache
}

struct RatesRepositoryResult: Equatable, Sendable {
    let snapshot: ExchangeRatesSnapshot
    let source: RatesSnapshotSource
}

protocol RatesRepository: Sendable {
    func loadRatesSnapshot() async throws -> RatesRepositoryResult
}
