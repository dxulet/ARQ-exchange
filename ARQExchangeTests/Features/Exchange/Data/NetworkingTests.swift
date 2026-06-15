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

    func testTickerResponseDecodesIntoExchangeRate() throws {
        let json = TestFixtures.data("""
        {
          "ask": "17.4418000000",
          "bid": "17.4382000000",
          "book": "usdc_mxn",
          "date": "\(TestFixtures.timestamp)"
        }
        """)

        let tickerResponse = try JSONDecoder().decode(TickerResponse.self, from: json)
        let rate = try TickerMapper().makeExchangeRate(from: tickerResponse)

        XCTAssertEqual(rate.base, .usdc)
        XCTAssertEqual(rate.quote, .mxn)
        XCTAssertEqual(rate.bid, TestFixtures.apiMXNRate.bid)
        XCTAssertEqual(rate.ask, TestFixtures.apiMXNRate.ask)
        XCTAssertEqual(rate.timestamp, TestFixtures.timestamp)
    }

    func testTickerResponseRejectsUnsupportedBook() throws {
        let tickerResponse = TickerResponse(
            ask: "17.4418000000",
            bid: "17.4382000000",
            currencyPairCode: "mxn_usdc",
            timestamp: TestFixtures.timestamp
        )

        XCTAssertThrowsError(try TickerMapper().makeExchangeRate(from: tickerResponse))
    }

    func testTickerResponseRejectsBookWithEmptyComponent() throws {
        let tickerResponse = TickerResponse(
            ask: "17.4418000000",
            bid: "17.4382000000",
            currencyPairCode: "usdc__mxn",
            timestamp: TestFixtures.timestamp
        )

        XCTAssertThrowsError(try TickerMapper().makeExchangeRate(from: tickerResponse))
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
        let tickerResponse = TickerResponse(
            ask: "17.4418000000",
            bid: "17.4382000000",
            currencyPairCode: "usdc_mxn",
            timestamp: TestFixtures.timestamp
        )
        let client = MockAPIClient(tickersResult: .success([tickerResponse]))
        let service = LiveRatesService(client: client)

        let rates = try await service.fetchRates(for: [.mxn])

        XCTAssertEqual(rates, [TestFixtures.apiMXNRate])
        XCTAssertEqual(client.requestedEndpoints, [.tickers(currencies: [.mxn])])
    }

    func testLiveRatesServiceSkipsInvalidTickerResponses() async throws {
        let validTicker = TickerResponse(
            ask: "17.4418000000",
            bid: "17.4382000000",
            currencyPairCode: "usdc_mxn",
            timestamp: TestFixtures.timestamp
        )
        let invalidTicker = TickerResponse(
            ask: "not-a-decimal",
            bid: "17.4382000000",
            currencyPairCode: "usdc_ars",
            timestamp: TestFixtures.timestamp
        )
        let client = MockAPIClient(
            tickersResult: .success([validTicker, invalidTicker])
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

    func testLiveRatesServiceDoesNotRequestUSDcRate() async throws {
        let client = MockAPIClient()
        let service = LiveRatesService(client: client)

        let rates = try await service.fetchRates(for: [.usdc])

        XCTAssertEqual(rates, [])
        XCTAssertEqual(client.requestedEndpoints, [])
    }

    func testLiveRatesServiceRequestsOnlyUniqueLocalRates() async throws {
        let client = MockAPIClient()
        let service = LiveRatesService(client: client)

        _ = try await service.fetchRates(for: [.usdc, .mxn, .mxn, .ars])

        XCTAssertEqual(client.requestedEndpoints, [.tickers(currencies: [.mxn, .ars])])
    }
}

private final class MockAPIClient: APIClientSending, @unchecked Sendable {
    private let tickerCurrenciesResult: Result<[String], Error>
    private let tickersResult: Result<[TickerResponse], Error>
    private(set) var requestedEndpoints: [APIEndpoint] = []

    init(
        tickerCurrenciesResult: Result<[String], Error> = .success([]),
        tickersResult: Result<[TickerResponse], Error> = .success([])
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
