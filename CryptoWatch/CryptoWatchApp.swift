import SwiftUI
import SwiftData

@main
struct CryptoWatchApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [FavoriteCoin.self, PriceAlert.self])
    }
}
