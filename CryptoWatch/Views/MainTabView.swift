import SwiftUI
import SwiftData
import UserNotifications

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CoinViewModel()
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeRaw) ?? .system
    }

    var body: some View {
        TabView {
            CoinListView(viewModel: viewModel)
                .tabItem {
                    Label("Moedas", systemImage: "bitcoinsign.circle.fill")
                }

            FavoritesListView(viewModel: viewModel)
                .tabItem {
                    Label("Favoritos", systemImage: "heart.fill")
                }

            TopGainersView(viewModel: viewModel)
                .tabItem {
                    Label("Em Alta", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .preferredColorScheme(appTheme.colorScheme)
        .task {
            UNUserNotificationCenter.current().delegate = ForegroundNotificationPresenter.shared
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadCoins()
        }
    }
}

#Preview {
    MainTabView()
}
