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
            client: APIClient(configuration: APIConfiguration.production),
            logger: logger
        )

        return AppDependencies(
            ratesRepository: LiveRatesRepository(
                ratesService: ratesService,
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
