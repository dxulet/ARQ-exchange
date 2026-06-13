@testable import ARQExchange

actor InMemoryRatesSnapshotCache: RatesSnapshotCaching {
    private var cachedSnapshot: ExchangeRatesSnapshot?

    init(snapshot: ExchangeRatesSnapshot? = nil) {
        cachedSnapshot = snapshot
    }

    func snapshot() async -> ExchangeRatesSnapshot? {
        cachedSnapshot
    }

    func store(_ snapshot: ExchangeRatesSnapshot) async {
        cachedSnapshot = snapshot
    }
}
