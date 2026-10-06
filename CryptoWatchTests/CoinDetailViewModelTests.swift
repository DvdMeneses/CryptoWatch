import Testing
import Foundation
@testable import CryptoWatch

@MainActor
struct CoinDetailViewModelTests {

    @Test func loadHistorySucceedsAndStoresPoints() async {
        let service = MockCoinService()
        let points = [
            PricePoint(date: Date(), price: 100),
            PricePoint(date: Date(), price: 110),
        ]
        service.historyResult = .success(points)
        let viewModel = CoinDetailViewModel(coinService: service)

        await viewModel.loadHistory(coinID: "bitcoin", days: 7)

        #expect(viewModel.pricePoints.count == 2)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func loadHistoryKeepsPreviousPointsWhenRefreshFails() async {
        let service = MockCoinService()
        service.historyResult = .success([PricePoint(date: Date(), price: 100)])
        let viewModel = CoinDetailViewModel(coinService: service)
        await viewModel.loadHistory(coinID: "bitcoin", days: 7)
        #expect(viewModel.pricePoints.count == 1)

        service.historyResult = .failure(TestError.generic)
        await viewModel.loadHistory(coinID: "bitcoin", days: 30)

        #expect(viewModel.pricePoints.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func staleResponseIsDiscardedInFavorOfNewerRequest() async {
        let service = MockCoinService()
        let viewModel = CoinDetailViewModel(coinService: service)

        service.historyResult = .success([PricePoint(date: Date(), price: 1)])
        service.fetchHistoryDelayNanoseconds = 100_000_000
        let staleTask = Task { await viewModel.loadHistory(coinID: "bitcoin", days: 7) }

        try? await Task.sleep(nanoseconds: 10_000_000)

        service.historyResult = .success([PricePoint(date: Date(), price: 2), PricePoint(date: Date(), price: 2)])
        service.fetchHistoryDelayNanoseconds = 0
        await viewModel.loadHistory(coinID: "bitcoin", days: 30)

        _ = await staleTask.value

        #expect(viewModel.pricePoints.count == 2)
    }
}
