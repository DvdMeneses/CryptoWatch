import SwiftData

@Model
class PriceAlert {
    @Attribute(.unique) var coinID: String
    var coinName: String
    var targetPrice: Double

    init(coinID: String, coinName: String, targetPrice: Double) {
        self.coinID = coinID
        self.coinName = coinName
        self.targetPrice = targetPrice
    }
}
