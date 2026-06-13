import Foundation

protocol APIClientSending: Sendable {
    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T
}

struct APIClient: APIClientSending {
    private let configuration: APIConfiguration
    private let urlSession: URLSession

    init(
        configuration: APIConfiguration = .production,
        urlSession: URLSession = APIClient.makeDefaultURLSession()
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    private static func makeDefaultURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024
        )
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration)
    }

    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.request(configuration: configuration)
        let responsePayload = try await data(for: request, endpoint: endpoint)
        try validate(responsePayload.response, endpoint: endpoint)
        return try decode(type, from: responsePayload.data, endpoint: endpoint)
    }

    private func data(for request: URLRequest, endpoint: APIEndpoint) async throws -> (data: Data, response: URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch {
            throw APIError.transport(endpoint: endpoint, underlying: error)
        }
    }

    private func validate(_ response: URLResponse, endpoint: APIEndpoint) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(endpoint: endpoint)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.httpStatus(httpResponse.statusCode, endpoint: endpoint)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, endpoint: APIEndpoint) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decoding(endpoint: endpoint, type: String(describing: type), underlying: error)
        }
    }
}
