import Foundation
@testable import CryptoWatch

final class MockCoinService: CoinServiceProtocol {
    var coinsResult: Result<[Coin], Error> = .success([])
    var historyResult: Result<[PricePoint], Error> = .success([])
    var fetchCoinsCallCount = 0
    var fetchHistoryDelayNanoseconds: UInt64 = 0

    func fetchCoins() async throws -> [Coin] {
        fetchCoinsCallCount += 1
        switch coinsResult {
        case .success(let coins): return coins
        case .failure(let error): throw error
        }
    }

    func fetchPriceHistory(coinID: String, days: Int) async throws -> [PricePoint] {
        if fetchHistoryDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: fetchHistoryDelayNanoseconds)
        }
        switch historyResult {
        case .success(let points): return points
        case .failure(let error): throw error
        }
    }
}

final class MockNotificationService: NotificationServiceProtocol {
    var authorizationGranted = true
    private(set) var firedAlerts: [(coinName: String, targetPrice: Double, currentPrice: Double)] = []

    func requestAuthorization() async -> Bool {
        authorizationGranted
    }

    func fireAlert(coinName: String, targetPrice: Double, currentPrice: Double) {
        firedAlerts.append((coinName, targetPrice, currentPrice))
    }
}

enum TestError: Error {
    case generic
}

extension Coin {
    static func stub(
        id: String = "bitcoin",
        symbol: String = "btc",
        name: String = "Bitcoin",
        currentPrice: Double = 60000,
        priceChangePercentage24h: Double? = 1.5
    ) -> Coin {
        Coin(
            id: id,
            symbol: symbol,
            name: name,
            image: "",
            currentPrice: currentPrice,
            priceChangePercentage24h: priceChangePercentage24h
        )
    }
}
