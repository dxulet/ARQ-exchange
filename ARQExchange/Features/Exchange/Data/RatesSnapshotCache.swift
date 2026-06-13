import Foundation

protocol RatesSnapshotCaching: Sendable {
    func snapshot() async -> ExchangeRatesSnapshot?
    func store(_ snapshot: ExchangeRatesSnapshot) async
}

actor DiskRatesSnapshotCache: RatesSnapshotCaching {
    private let fileURL: URL
    private let diagnostics: RatesDiagnostics
    private var memorySnapshot: ExchangeRatesSnapshot?

    init(
        fileURL: URL = DiskRatesSnapshotCache.defaultFileURL(),
        diagnostics: RatesDiagnostics = NoopRatesDiagnostics()
    ) {
        self.fileURL = fileURL
        self.diagnostics = diagnostics
    }

    func snapshot() async -> ExchangeRatesSnapshot? {
        if let memorySnapshot {
            return memorySnapshot
        }

        let diskResult = await Self.loadSnapshot(from: fileURL)
        if let failureReason = diskResult.failureReason {
            diagnostics.record(.cacheReadFailed(reason: failureReason))
        }

        guard let diskSnapshot = diskResult.snapshot else {
            return nil
        }

        memorySnapshot = diskSnapshot
        return diskSnapshot
    }

    func store(_ snapshot: ExchangeRatesSnapshot) async {
        memorySnapshot = snapshot
        if let failureReason = await Self.storeSnapshot(snapshot, at: fileURL) {
            diagnostics.record(.cacheWriteFailed(reason: failureReason))
        }
    }

    private static func defaultFileURL() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return cacheDirectory.appendingPathComponent("exchange-rates-snapshot.json")
    }

    private static func loadSnapshot(from url: URL) async -> (snapshot: ExchangeRatesSnapshot?, failureReason: String?) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return (snapshot: nil, failureReason: nil)
        }

        let task = Task.detached(priority: .utility) { () -> (snapshot: ExchangeRatesSnapshot?, failureReason: String?) in
            do {
                let data = try Data(contentsOf: url)
                let payload = try JSONDecoder().decode(PersistedRatesSnapshot.self, from: data)
                return (snapshot: payload.snapshot, failureReason: nil)
            } catch {
                return (snapshot: nil, failureReason: String(describing: error))
            }
        }

        return await task.value
    }

    private static func storeSnapshot(_ snapshot: ExchangeRatesSnapshot, at url: URL) async -> String? {
        let task = Task.detached(priority: .utility) { () -> String? in
            do {
                let directory = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let data = try JSONEncoder().encode(PersistedRatesSnapshot(snapshot: snapshot))
                try data.write(to: url, options: [.atomic])
                return nil
            } catch {
                return String(describing: error)
            }
        }

        return await task.value
    }
}

private struct PersistedRatesSnapshot: Codable, Sendable {
    let availableCurrencies: [CurrencyCode]
    let rates: [ExchangeRate]
    let fetchedAt: Date
    let currencyDiscoverySource: CurrencyDiscoverySource

    init(snapshot: ExchangeRatesSnapshot) {
        availableCurrencies = snapshot.availableCurrencies
        rates = snapshot.ratesByCurrency.values.sorted { $0.quote.rawValue < $1.quote.rawValue }
        fetchedAt = snapshot.fetchedAt
        currencyDiscoverySource = snapshot.currencyDiscoverySource
    }

    var snapshot: ExchangeRatesSnapshot {
        ExchangeRatesSnapshot(
            availableCurrencies: availableCurrencies,
            ratesByCurrency: Dictionary(
                rates.map { ($0.quote, $0) },
                uniquingKeysWith: { existingRate, _ in existingRate }
            ),
            fetchedAt: fetchedAt,
            currencyDiscoverySource: currencyDiscoverySource
        )
    }
}
