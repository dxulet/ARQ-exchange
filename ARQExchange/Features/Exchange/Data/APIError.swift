enum APIError: Error {
    case invalidURL
    case invalidResponse(endpoint: APIEndpoint)
    case httpStatus(Int, endpoint: APIEndpoint)
    case decoding(endpoint: APIEndpoint, type: String, underlying: Error)
    case transport(endpoint: APIEndpoint, underlying: Error)
}

extension APIError: Equatable {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case let (.invalidResponse(lhsEndpoint), .invalidResponse(rhsEndpoint)):
            return lhsEndpoint == rhsEndpoint
        case let (.httpStatus(lhsStatus, lhsEndpoint), .httpStatus(rhsStatus, rhsEndpoint)):
            return lhsStatus == rhsStatus && lhsEndpoint == rhsEndpoint
        case let (.decoding(lhsEndpoint, lhsType, _), .decoding(rhsEndpoint, rhsType, _)):
            return lhsEndpoint == rhsEndpoint && lhsType == rhsType
        case let (.transport(lhsEndpoint, _), .transport(rhsEndpoint, _)):
            return lhsEndpoint == rhsEndpoint
        default:
            return false
        }
    }
}
