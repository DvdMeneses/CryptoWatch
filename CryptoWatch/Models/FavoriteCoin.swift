import SwiftData

@Model
class FavoriteCoin {
    @Attribute(.unique) var coinID: String

    init(coinID: String) {
        self.coinID = coinID
    }
}
