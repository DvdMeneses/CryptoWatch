import Foundation
import SwiftData


@Observable
class CoinViewModel {
    var coins: [Coin] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var favoriteIDs: Set<String> = []
    var alertsByCoinID: [String: PriceAlert] = [:]

    private let coinsService: CoinServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var modelContext: ModelContext?

    init(
        coinsService: CoinServiceProtocol = CoinService(),
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.coinsService = coinsService
        self.notificationService = notificationService
    }

    var favoriteCoins: [Coin] {
        coins.filter { favoriteIDs.contains($0.id) }
    }

    var topGainers: [Coin] {
        coins
            .filter { ($0.priceChangePercentage24h ?? 0) > 0 }
            .sorted { ($0.priceChangePercentage24h ?? 0) > ($1.priceChangePercentage24h ?? 0) }
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFavoritesFromDisk()
        loadAlertsFromDisk()
    }

    private func loadFavoritesFromDisk() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<FavoriteCoin>()
        if let saved = try? modelContext.fetch(descriptor) {
            favoriteIDs = Set(saved.map { $0.coinID })
        }
    }

    private func loadAlertsFromDisk() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<PriceAlert>()
        if let saved = try? modelContext.fetch(descriptor) {
            alertsByCoinID = Dictionary(uniqueKeysWithValues: saved.map { ($0.coinID, $0) })
        }
    }

    func loadCoins() async {
        print("[CoinViewModel] loadCoins chamado, já tinha \(coins.count) moedas")
        let hadData = !coins.isEmpty
        if !hadData {
            isLoading = true
            errorMessage = nil
        }
        do {
            let fetched = try await coinsService.fetchCoins()
            coins = fetched
            errorMessage = nil
            print("[CoinViewModel] loadCoins sucesso, \(fetched.count) moedas")
            checkPriceAlerts()
        } catch {
            print("[CoinViewModel] loadCoins falhou hadData=\(hadData) erro=\(error)")
            if !hadData {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func isFavorite(_ coin: Coin) -> Bool {
        favoriteIDs.contains(coin.id)
    }

    func toggleFavorite(_ coin: Coin) {
        if favoriteIDs.contains(coin.id) {
            removeFavorite(coin)
        } else {
            addFavorite(coin)
        }
    }

    func addFavorite(_ coin: Coin) {
        print("[CoinViewModel] addFavorite(\(coin.name))")
        guard !favoriteIDs.contains(coin.id) else { return }
        favoriteIDs.insert(coin.id)
        guard let modelContext else { return }
        modelContext.insert(FavoriteCoin(coinID: coin.id))
        try? modelContext.save()
    }

    func removeFavorite(_ coin: Coin) {
        print("[CoinViewModel] removeFavorite(\(coin.name))")
        favoriteIDs.remove(coin.id)
        guard let modelContext else { return }
        let targetID = coin.id
        let descriptor = FetchDescriptor<FavoriteCoin>(
            predicate: #Predicate { $0.coinID == targetID }
        )
        if let matches = try? modelContext.fetch(descriptor) {
            matches.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }

    func alert(for coin: Coin) -> PriceAlert? {
        alertsByCoinID[coin.id]
    }

    func setAlert(for coin: Coin, targetPrice: Double) async {
        print("[CoinViewModel] setAlert(\(coin.name), target=\(targetPrice))")
        let granted = await notificationService.requestAuthorization()
        guard granted else {
            print("[CoinViewModel] notificações não autorizadas, alerta não salvo")
            return
        }
        guard let modelContext else { return }
        removeAlert(for: coin)
        let newAlert = PriceAlert(coinID: coin.id, coinName: coin.name, targetPrice: targetPrice)
        modelContext.insert(newAlert)
        try? modelContext.save()
        alertsByCoinID[coin.id] = newAlert
        checkPriceAlerts()
    }

    func removeAlert(for coin: Coin) {
        print("[CoinViewModel] removeAlert(\(coin.name))")
        alertsByCoinID[coin.id] = nil
        guard let modelContext else { return }
        let targetID = coin.id
        let descriptor = FetchDescriptor<PriceAlert>(
            predicate: #Predicate { $0.coinID == targetID }
        )
        if let matches = try? modelContext.fetch(descriptor) {
            matches.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }

    private func checkPriceAlerts() {
        guard let modelContext else { return }
        guard !alertsByCoinID.isEmpty else { return }

        for alert in alertsByCoinID.values {
            guard let coin = coins.first(where: { $0.id == alert.coinID }) else { continue }
            if coin.currentPrice >= alert.targetPrice {
                print("[CoinViewModel] alerta disparado: \(coin.name) chegou em \(coin.currentPrice), alvo era \(alert.targetPrice)")
                notificationService.fireAlert(
                    coinName: coin.name,
                    targetPrice: alert.targetPrice,
                    currentPrice: coin.currentPrice
                )
                modelContext.delete(alert)
                alertsByCoinID[alert.coinID] = nil
            }
        }
        try? modelContext.save()
    }
}
