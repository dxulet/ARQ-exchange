struct APIConfiguration: Equatable, Sendable {
    static let production = APIConfiguration(
        scheme: "https",
        host: "api.dolarapp.dev"
    )

    let scheme: String
    let host: String

    enum Path {
        static let tickers = "/v1/tickers"
        static let tickerCurrencies = "/v1/tickers-currencies"
    }

    enum Query {
        static let currencies = "currencies"
    }
}
