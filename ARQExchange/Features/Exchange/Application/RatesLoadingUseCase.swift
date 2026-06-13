struct RatesLoadingUseCase: Sendable {
    private let ratesRepository: RatesRepository

    init(ratesRepository: RatesRepository) {
        self.ratesRepository = ratesRepository
    }

    func loadRatesSnapshot(forceRefresh: Bool = false) async throws -> RatesRepositoryResult {
        try await ratesRepository.loadRatesSnapshot(forceRefresh: forceRefresh)
    }
}
