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
    let logger: ExchangeLogger

    static let live: AppDependencies = {
        let logger = ExchangeLogger.osLog()
        let ratesService = LiveRatesService(
            client: APIClient(),
            logger: logger
        )
        let cache = DiskRatesSnapshotCache(logger: logger)

        return AppDependencies(
            ratesRepository: LiveRatesRepository(
                ratesService: ratesService,
                cache: cache,
                logger: logger
            ),
            logger: logger
        )
    }()

    var exchangeFeatureDependencies: ExchangeFeatureDependencies {
        ExchangeFeatureDependencies(
            ratesRepository: ratesRepository,
            logger: logger
        )
    }
}
