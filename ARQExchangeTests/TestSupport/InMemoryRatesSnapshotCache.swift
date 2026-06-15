@testable import ARQExchange
import Foundation

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

final class TestLogRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedEvents: [ExchangeLogEvent] = []

    var logger: ExchangeLogger {
        ExchangeLogger { [weak self] event in
            self?.record(event)
        }
    }

    var events: [ExchangeLogEvent] {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents
    }

    private func record(_ event: ExchangeLogEvent) {
        lock.lock()
        recordedEvents.append(event)
        lock.unlock()
    }
}
