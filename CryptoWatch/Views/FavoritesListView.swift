import SwiftUI

struct FavoritesListView: View {
    var viewModel: CoinViewModel

    var body: some View {
        NavigationStack {
            if viewModel.favoriteCoins.isEmpty {
                ContentUnavailableView(
                    "Nenhum favorito ainda",
                    systemImage: "heart",
                    description: Text("Arraste uma moeda pra esquerda na aba Moedas pra favoritar.")
                )
            } else {
                List(viewModel.favoriteCoins) { coin in
                    NavigationLink {
                        CoinDetailView(coin: coin, coinViewModel: viewModel)
                    } label: {
                        HStack {
                            AsyncImage(url: URL(string: coin.image)) { image in
                                image.resizable()
                            } placeholder: {
                                Circle().fill(.secondary.opacity(0.2))
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())

                            Text(coin.name)

                            Spacer()

                            let change = coin.priceChangePercentage24h ?? 0
                            let isUp = change >= 0
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(coin.currentPrice, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                HStack(spacing: 2) {
                                    Image(systemName: isUp ? "arrow.up" : "arrow.down")
                                        .font(.caption2)
                                    Text("\(change, specifier: "%.2f")%")
                                        .font(.caption)
                                }
                                .foregroundStyle(isUp ? .green : .red)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeFavorite(coin)
                        } label: {
                            Label("Remover", systemImage: "heart.slash.fill")
                        }
                    }
                }
                .refreshable {
                    await viewModel.loadCoins()
                }
            }
        }
    }
}

#Preview {
    FavoritesListView(viewModel: CoinViewModel())
}
