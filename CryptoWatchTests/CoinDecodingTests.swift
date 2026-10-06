import Testing
import Foundation
@testable import CryptoWatch

struct CoinDecodingTests {

    @Test func decodesSnakeCaseFieldsCorrectly() throws {
        let json = """
        [
          {
            "id": "bitcoin",
            "symbol": "btc",
            "name": "Bitcoin",
            "image": "https://example.com/bitcoin.png",
            "current_price": 62345.67,
            "price_change_percentage_24h": -3.21
          }
        ]
        """.data(using: .utf8)!

        let coins = try JSONDecoder().decode([Coin].self, from: json)

        #expect(coins.count == 1)
        #expect(coins[0].id == "bitcoin")
        #expect(coins[0].currentPrice == 62345.67)
        #expect(coins[0].priceChangePercentage24h == -3.21)
    }

    @Test func decodesMissingPriceChangeAsNil() throws {
        let json = """
        [
          {
            "id": "ethereum",
            "symbol": "eth",
            "name": "Ethereum",
            "image": "https://example.com/eth.png",
            "current_price": 2500.0
          }
        ]
        """.data(using: .utf8)!

        let coins = try JSONDecoder().decode([Coin].self, from: json)

        #expect(coins[0].priceChangePercentage24h == nil)
    }
}
