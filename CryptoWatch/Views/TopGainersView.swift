import SwiftUI

struct TopGainersView: View {
    var viewModel: CoinViewModel

    var body: some View {
        NavigationStack {
            if viewModel.topGainers.isEmpty {
                ContentUnavailableView(
                    "Sem moedas em alta agora",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Puxe pra atualizar quando a lista carregar.")
                )
            } else {
                List(viewModel.topGainers) { coin in
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

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(coin.currentPrice, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.up")
                                        .font(.caption2)
                                    Text("\(coin.priceChangePercentage24h ?? 0, specifier: "%.2f")%")
                                        .font(.caption)
                                }
                                .foregroundStyle(.green)
                            }
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
    TopGainersView(viewModel: CoinViewModel())
}
