import Foundation

enum APIEndpoint: Equatable, Sendable {
    case tickers(currencies: [CurrencyCode])
    case tickerCurrencies

    var timeoutInterval: TimeInterval {
        switch self {
        case .tickerCurrencies:
            return 3
        case .tickers:
            return 10
        }
    }

    private func url(configuration: APIConfiguration) throws -> URL {
        var components = URLComponents()
        components.scheme = configuration.scheme
        components.host = configuration.host
        return try url(components: components)
    }

    func request(configuration: APIConfiguration) throws -> URLRequest {
        let url = try url(configuration: configuration)
        return URLRequest(url: url, timeoutInterval: timeoutInterval)
    }

    func url(baseURL: URL) throws -> URL {
        guard let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        return try url(components: components)
    }

    private func url(components baseComponents: URLComponents) throws -> URL {
        var components = baseComponents

        switch self {
        case let .tickers(currencies):
            components.path = APIConfiguration.Path.tickers
            let values = currencies.map(\.rawValue).joined(separator: ",")
            components.queryItems = [
                URLQueryItem(name: APIConfiguration.Query.currencies, value: values)
            ]
        case .tickerCurrencies:
            components.path = APIConfiguration.Path.tickerCurrencies
            components.queryItems = nil
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        return url
    }
}
