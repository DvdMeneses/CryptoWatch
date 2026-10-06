import Testing
import SwiftData
@testable import CryptoWatch

@MainActor
struct CoinViewModelTests {

    private func makeInMemoryContext() -> ModelContext {
        let schema = Schema([FavoriteCoin.self, PriceAlert.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func topGainersFiltersAndSortsDescending() async {
        let service = MockCoinService()
        service.coinsResult = .success([
            .stub(id: "a", priceChangePercentage24h: 2),
            .stub(id: "b", priceChangePercentage24h: -5),
            .stub(id: "c", priceChangePercentage24h: 10),
            .stub(id: "d", priceChangePercentage24h: nil),
        ])
        let viewModel = CoinViewModel(coinsService: service, notificationService: MockNotificationService())
        await viewModel.loadCoins()

        #expect(viewModel.topGainers.map(\.id) == ["c", "a"])
    }

    @Test func loadCoinsKeepsPreviousDataWhenRefreshFails() async {
        let service = MockCoinService()
        service.coinsResult = .success([.stub(id: "bitcoin")])
        let viewModel = CoinViewModel(coinsService: service, notificationService: MockNotificationService())
        await viewModel.loadCoins()
        #expect(viewModel.coins.count == 1)
        #expect(viewModel.errorMessage == nil)

        service.coinsResult = .failure(TestError.generic)
        await viewModel.loadCoins()

        #expect(viewModel.coins.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func loadCoinsSetsErrorOnFirstLoadFailure() async {
        let service = MockCoinService()
        service.coinsResult = .failure(TestError.generic)
        let viewModel = CoinViewModel(coinsService: service, notificationService: MockNotificationService())
        await viewModel.loadCoins()

        #expect(viewModel.coins.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func addAndRemoveFavoritePersistsToDisk() {
        let context = makeInMemoryContext()
        let viewModel = CoinViewModel(coinsService: MockCoinService(), notificationService: MockNotificationService())
        viewModel.configure(modelContext: context)
        let coin = Coin.stub(id: "bitcoin")

        viewModel.addFavorite(coin)
        #expect(viewModel.isFavorite(coin))
        #expect(try! context.fetch(FetchDescriptor<FavoriteCoin>()).count == 1)

        viewModel.removeFavorite(coin)
        #expect(!viewModel.isFavorite(coin))
        #expect(try! context.fetch(FetchDescriptor<FavoriteCoin>()).isEmpty)
    }

    @Test func toggleFavoriteSwitchesState() {
        let context = makeInMemoryContext()
        let viewModel = CoinViewModel(coinsService: MockCoinService(), notificationService: MockNotificationService())
        viewModel.configure(modelContext: context)
        let coin = Coin.stub(id: "bitcoin")

        viewModel.toggleFavorite(coin)
        #expect(viewModel.isFavorite(coin))

        viewModel.toggleFavorite(coin)
        #expect(!viewModel.isFavorite(coin))
    }

    @Test func setAlertFiresImmediatelyWhenTargetAlreadyReached() async {
        let context = makeInMemoryContext()
        let service = MockCoinService()
        let coin = Coin.stub(id: "bitcoin", currentPrice: 70000)
        service.coinsResult = .success([coin])
        let notifications = MockNotificationService()
        let viewModel = CoinViewModel(coinsService: service, notificationService: notifications)
        viewModel.configure(modelContext: context)
        await viewModel.loadCoins()

        await viewModel.setAlert(for: coin, targetPrice: 65000)

        #expect(notifications.firedAlerts.count == 1)
        #expect(notifications.firedAlerts.first?.coinName == "Bitcoin")
        #expect(viewModel.alert(for: coin) == nil)
        #expect(try! context.fetch(FetchDescriptor<PriceAlert>()).isEmpty)
    }

    @Test func setAlertPersistsWhenTargetNotYetReached() async {
        let context = makeInMemoryContext()
        let service = MockCoinService()
        let coin = Coin.stub(id: "bitcoin", currentPrice: 50000)
        service.coinsResult = .success([coin])
        let notifications = MockNotificationService()
        let viewModel = CoinViewModel(coinsService: service, notificationService: notifications)
        viewModel.configure(modelContext: context)
        await viewModel.loadCoins()

        await viewModel.setAlert(for: coin, targetPrice: 65000)

        #expect(notifications.firedAlerts.isEmpty)
        #expect(viewModel.alert(for: coin)?.targetPrice == 65000)
        #expect(try! context.fetch(FetchDescriptor<PriceAlert>()).count == 1)
    }

    @Test func removeAlertClearsStateAndDisk() async {
        let context = makeInMemoryContext()
        let service = MockCoinService()
        let coin = Coin.stub(id: "bitcoin", currentPrice: 50000)
        service.coinsResult = .success([coin])
        let viewModel = CoinViewModel(coinsService: service, notificationService: MockNotificationService())
        viewModel.configure(modelContext: context)
        await viewModel.loadCoins()
        await viewModel.setAlert(for: coin, targetPrice: 65000)

        viewModel.removeAlert(for: coin)

        #expect(viewModel.alert(for: coin) == nil)
        #expect(try! context.fetch(FetchDescriptor<PriceAlert>()).isEmpty)
    }

    @Test func setAlertDoesNothingWhenAuthorizationDenied() async {
        let context = makeInMemoryContext()
        let service = MockCoinService()
        let coin = Coin.stub(id: "bitcoin", currentPrice: 50000)
        service.coinsResult = .success([coin])
        let notifications = MockNotificationService()
        notifications.authorizationGranted = false
        let viewModel = CoinViewModel(coinsService: service, notificationService: notifications)
        viewModel.configure(modelContext: context)
        await viewModel.loadCoins()

        await viewModel.setAlert(for: coin, targetPrice: 65000)

        #expect(viewModel.alert(for: coin) == nil)
        #expect(try! context.fetch(FetchDescriptor<PriceAlert>()).isEmpty)
    }
}
