import Foundation
@testable import ARQExchange

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
