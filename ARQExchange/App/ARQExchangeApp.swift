import SwiftUI

@main
struct ARQExchangeApp: App {
    private let dependencies = AppDependencies.live

    var body: some Scene {
        WindowGroup {
            ExchangeFeatureView(dependencies: dependencies.exchangeFeatureDependencies)
        }
    }
}

private struct AppDependencies {
    let ratesRepository: RatesRepository
    let analyticsClient: AnalyticsClient

    static let live: AppDependencies = {
        let diagnostics = OSLogRatesDiagnostics()
        let ratesService = LiveRatesService(
            client: APIClient(),
            diagnostics: diagnostics
        )
        let cache = DiskRatesSnapshotCache(diagnostics: diagnostics)

        return AppDependencies(
            ratesRepository: LiveRatesRepository(
                ratesService: ratesService,
                cache: cache,
                diagnostics: diagnostics
            ),
            analyticsClient: OSLogAnalyticsClient()
        )
    }()

    var exchangeFeatureDependencies: ExchangeFeatureDependencies {
        ExchangeFeatureDependencies(
            ratesRepository: ratesRepository,
            analyticsClient: analyticsClient
        )
    }
}
