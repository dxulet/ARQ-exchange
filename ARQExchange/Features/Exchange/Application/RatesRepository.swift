enum RatesSnapshotSource: String, Equatable, Sendable {
    case network
    case freshCache
    case staleCache
}

struct RatesRepositoryResult: Equatable, Sendable {
    let snapshot: ExchangeRatesSnapshot
    let source: RatesSnapshotSource
}

protocol RatesRepository: Sendable {
    func loadRatesSnapshot(forceRefresh: Bool) async throws -> RatesRepositoryResult
}
