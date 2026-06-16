import Foundation
import XCTest
@testable import ARQExchange

final class NetworkingTests: XCTestCase {
    func testTickersEndpointBuildsExpectedURL() throws {
        let endpoint = APIEndpoint.tickers(currencies: [.mxn, .ars])

        let url = try endpoint.url(baseURL: TestFixtures.apiBaseURL)

        XCTAssertEqual(
            url.absoluteString,
            "\(TestFixtures.apiBaseURL.absoluteString)\(APIConfiguration.Path.tickers)?\(APIConfiguration.Query.currencies)=MXN,ARS"
        )
    }

    func testTickerCurrenciesEndpointBuildsExpectedURL() throws {
        let endpoint = APIEndpoint.tickerCurrencies

        let url = try endpoint.url(baseURL: TestFixtures.apiBaseURL)

        XCTAssertEqual(
            url.absoluteString,
            "\(TestFixtures.apiBaseURL.absoluteString)\(APIConfiguration.Path.tickerCurrencies)"
        )
    }

    func testTickerDTODecodesIntoExchangeRate() throws {
        let json = TestFixtures.data("""
        {
          "ask": "17.4418000000",
          "bid": "17.4382000000",
          "book": "usdc_mxn",
          "date": "\(TestFixtures.timestamp)"
        }
        """)

        let tickerDTO = try JSONDecoder().decode(TickerDTO.self, from: json)
        let rate = try TickerMapper().makeExchangeRate(from: tickerDTO)

        XCTAssertEqual(rate.base, .usdc)
        XCTAssertEqual(rate.quote, .mxn)
        XCTAssertEqual(rate.bid, TestFixtures.apiMXNRate.bid)
        XCTAssertEqual(rate.ask, TestFixtures.apiMXNRate.ask)
        XCTAssertEqual(rate.timestamp, TestFixtures.timestamp)
    }

    func testTickerDTORejectsUnsupportedBook() throws {
        let tickerDTO = TickerDTO(
            ask: "17.4418000000",
            bid: "17.4382000000",
            currencyPairCode: "mxn_usdc",
            timestamp: TestFixtures.timestamp
        )

        XCTAssertThrowsError(try TickerMapper().makeExchangeRate(from: tickerDTO))
    }

    func testTickerDTORejectsBookWithEmptyComponent() throws {
        let tickerDTO = TickerDTO(
            ask: "17.4418000000",
            bid: "17.4382000000",
            currencyPairCode: "usdc__mxn",
            timestamp: TestFixtures.timestamp
        )

        XCTAssertThrowsError(try TickerMapper().makeExchangeRate(from: tickerDTO))
    }

    func testTickerDTORejectsNonPositiveRates() {
        let tickerDTO = TickerDTO(
            ask: "0",
            bid: "-17.4382000000",
            currencyPairCode: "usdc_mxn",
            timestamp: TestFixtures.timestamp
        )

        XCTAssertThrowsError(try TickerMapper().makeExchangeRate(from: tickerDTO)) { error in
            XCTAssertEqual(
                error as? TickerMappingError,
                .nonPositiveDecimal(field: "ask", value: "0")
            )
        }
    }

    func testLiveRatesServiceFallsBackWhenCurrenciesEndpointFails() async throws {
        let client = MockAPIClient(
            tickerCurrenciesResult: .failure(APIError.httpStatus(403, endpoint: .tickerCurrencies))
        )
        let logRecorder = TestLogRecorder()
        let service = LiveRatesService(client: client, logger: logRecorder.logger)

        let discovery = try await service.fetchAvailableCurrencies()

        XCTAssertEqual(discovery.currencies, [.mxn, .ars, .brl, .cop])
        XCTAssertEqual(discovery.source, .fallbackError)
        XCTAssertEqual(client.requestedEndpoints, [.tickerCurrencies])
        XCTAssertEqual(logRecorder.events, [.currencyDiscoveryFallback(source: .fallbackError)])
    }

    func testLiveRatesServiceFallsBackWhenCurrenciesResponseIsEmpty() async throws {
        let client = MockAPIClient(tickerCurrenciesResult: .success([]))
        let logRecorder = TestLogRecorder()
        let service = LiveRatesService(client: client, logger: logRecorder.logger)

        let discovery = try await service.fetchAvailableCurrencies()

        XCTAssertEqual(discovery.currencies, [.mxn, .ars, .brl, .cop])
        XCTAssertEqual(discovery.source, .fallbackEmpty)
        XCTAssertEqual(client.requestedEndpoints, [.tickerCurrencies])
        XCTAssertEqual(logRecorder.events, [.currencyDiscoveryFallback(source: .fallbackEmpty)])
    }

    func testLiveRatesServicePreservesCancellationWhenCurrenciesRequestIsCancelled() async {
        let client = MockAPIClient(
            tickerCurrenciesResult: .failure(CancellationError())
        )
        let service = LiveRatesService(client: client)

        do {
            _ = try await service.fetchAvailableCurrencies()
            XCTFail("Expected cancellation to be preserved")
        } catch is CancellationError {
            XCTAssertEqual(client.requestedEndpoints, [.tickerCurrencies])
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testLiveRatesServiceKeepsUnknownAPICurrencies() async throws {
        let client = MockAPIClient(
            tickerCurrenciesResult: .success(["CLP", "MXN", "mxn", "USDc", " clp "])
        )
        let service = LiveRatesService(client: client)

        let discovery = try await service.fetchAvailableCurrencies()

        XCTAssertEqual(discovery.currencies.map(\.rawValue), ["CLP", "MXN"])
        XCTAssertEqual(discovery.source, .remote)
    }

    func testLiveRatesServiceFetchesRates() async throws {
        let client = MockAPIClient(tickersResult: .success([TestFixtures.apiMXNTicker]))
        let service = LiveRatesService(client: client)

        let rates = try await service.fetchRates(for: [.mxn])

        XCTAssertEqual(rates, [TestFixtures.apiMXNRate])
        XCTAssertEqual(client.requestedEndpoints, [.tickers(currencies: [.mxn])])
    }

    func testLiveRatesServiceSkipsInvalidTickerDTOs() async throws {
        let invalidTicker = TickerDTO(
            ask: "not-a-decimal",
            bid: "17.4382000000",
            currencyPairCode: "usdc_ars",
            timestamp: TestFixtures.timestamp
        )
        let client = MockAPIClient(
            tickersResult: .success([TestFixtures.apiMXNTicker, invalidTicker])
        )
        let logRecorder = TestLogRecorder()
        let service = LiveRatesService(client: client, logger: logRecorder.logger)

        let rates = try await service.fetchRates(for: [.mxn, .ars])

        XCTAssertEqual(rates, [TestFixtures.apiMXNRate])
        XCTAssertEqual(client.requestedEndpoints, [.tickers(currencies: [.mxn, .ars])])
        XCTAssertEqual(logRecorder.events.count, 1)
        guard case let .tickerMappingSkipped(book, reason) = logRecorder.events.first else {
            return XCTFail("Expected ticker mapping diagnostic")
        }
        XCTAssertEqual(book, "usdc_ars")
        XCTAssertTrue(reason.contains("invalidDecimal"))
    }

    func testLiveRatesServiceThrowsWhenNoUsableRatesAreReturned() async {
        let invalidTicker = TickerDTO(
            ask: "not-a-decimal",
            bid: "17.4382000000",
            currencyPairCode: "usdc_mxn",
            timestamp: TestFixtures.timestamp
        )
        let client = MockAPIClient(tickersResult: .success([invalidTicker]))
        let service = LiveRatesService(client: client)

        do {
            _ = try await service.fetchRates(for: [.mxn])
            XCTFail("Expected no usable rates error")
        } catch {
            XCTAssertEqual(
                error as? RatesServiceError,
                .noUsableRates(requestedCurrencies: [.mxn])
            )
            XCTAssertEqual(client.requestedEndpoints, [.tickers(currencies: [.mxn])])
        }
    }

    func testLiveRatesServiceThrowsWhenRatesResponseIsEmpty() async {
        let client = MockAPIClient(tickersResult: .success([]))
        let service = LiveRatesService(client: client)

        do {
            _ = try await service.fetchRates(for: [.mxn])
            XCTFail("Expected no usable rates error")
        } catch {
            XCTAssertEqual(
                error as? RatesServiceError,
                .noUsableRates(requestedCurrencies: [.mxn])
            )
            XCTAssertEqual(client.requestedEndpoints, [.tickers(currencies: [.mxn])])
        }
    }

    func testLiveRatesServiceDoesNotRequestUSDcRate() async throws {
        let client = MockAPIClient()
        let service = LiveRatesService(client: client)

        let rates = try await service.fetchRates(for: [.usdc])

        XCTAssertEqual(rates, [])
        XCTAssertEqual(client.requestedEndpoints, [])
    }

    func testLiveRatesServiceRequestsOnlyUniqueLocalRates() async throws {
        let client = MockAPIClient(tickersResult: .success([TestFixtures.apiMXNTicker]))
        let service = LiveRatesService(client: client)

        _ = try await service.fetchRates(for: [.usdc, .mxn, .mxn, .ars])

        XCTAssertEqual(client.requestedEndpoints, [.tickers(currencies: [.mxn, .ars])])
    }

    func testAPIClientMapsNon2xxResponse() async throws {
        URLProtocolStub.requestHandler = { request in
            (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data()
            )
        }
        addTeardownBlock { URLProtocolStub.requestHandler = nil }
        let client = makeStubbedAPIClient()

        do {
            _ = try await client.send(.tickerCurrencies, as: [String].self)
            XCTFail("Expected non-2xx response to throw")
        } catch {
            XCTAssertEqual(error as? APIError, .httpStatus(503, endpoint: .tickerCurrencies))
        }
    }

    func testAPIClientMapsDecodingFailure() async throws {
        URLProtocolStub.requestHandler = { request in
            (
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                TestFixtures.data(#"{"unexpected":true}"#)
            )
        }
        addTeardownBlock { URLProtocolStub.requestHandler = nil }
        let client = makeStubbedAPIClient()

        do {
            _ = try await client.send(.tickerCurrencies, as: [String].self)
            XCTFail("Expected decoding failure to throw")
        } catch let apiError as APIError {
            guard case let .decoding(endpoint, type, _) = apiError else {
                return XCTFail("Expected decoding error, got \(apiError)")
            }
            XCTAssertEqual(endpoint, .tickerCurrencies)
            XCTAssertEqual(type, String(describing: [String].self))
        } catch {
            XCTFail("Expected APIError, got \(error)")
        }
    }

    func testAPIClientMapsTransportFailure() async throws {
        URLProtocolStub.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        addTeardownBlock { URLProtocolStub.requestHandler = nil }
        let client = makeStubbedAPIClient()

        do {
            _ = try await client.send(.tickerCurrencies, as: [String].self)
            XCTFail("Expected transport failure to throw")
        } catch let apiError as APIError {
            guard case let .transport(endpoint, _) = apiError else {
                return XCTFail("Expected transport error, got \(apiError)")
            }
            XCTAssertEqual(endpoint, .tickerCurrencies)
        } catch {
            XCTFail("Expected APIError, got \(error)")
        }
    }

    private func makeStubbedAPIClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        return APIClient(
            configuration: APIConfiguration(scheme: "https", host: "example.test"),
            urlSession: session
        )
    }
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: TestError.unexpectedType)
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class MockAPIClient: APIClientSending, @unchecked Sendable {
    private let tickerCurrenciesResult: Result<[String], Error>
    private let tickersResult: Result<[TickerDTO], Error>
    private(set) var requestedEndpoints: [APIEndpoint] = []

    init(
        tickerCurrenciesResult: Result<[String], Error> = .success([]),
        tickersResult: Result<[TickerDTO], Error> = .success([])
    ) {
        self.tickerCurrenciesResult = tickerCurrenciesResult
        self.tickersResult = tickersResult
    }

    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        requestedEndpoints.append(endpoint)

        switch endpoint {
        case .tickerCurrencies:
            return try typedValue(tickerCurrenciesResult.get(), as: type)
        case .tickers:
            return try typedValue(tickersResult.get(), as: type)
        }
    }

    private func typedValue<T>(_ value: Any, as type: T.Type) throws -> T {
        guard let typedValue = value as? T else {
            throw APIError.decoding(endpoint: .tickerCurrencies, type: String(describing: T.self), underlying: TestError.unexpectedType)
        }

        return typedValue
    }
}

private enum TestError: Error {
    case unexpectedType
}
