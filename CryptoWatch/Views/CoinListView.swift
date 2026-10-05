//
//  ContentView.swift
//  CryptoWatch
//
//  Created by NUT - NUCLEO DE TECNOLOGIA on 04/10/26.
//

import SwiftUI

struct CoinListView: View {
    var viewModel: CoinViewModel
    @State private var searchText = ""
    @State private var showingSettings = false

    var filteredCoins: [Coin] {
        if searchText.isEmpty {
            return viewModel.coins
        }
        return viewModel.coins.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.coins.isEmpty {
                    ProgressView("Carregando...")
                } else if let error = viewModel.errorMessage, viewModel.coins.isEmpty {
                    ContentUnavailableView {
                        Label("Erro ao carregar", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Tentar de novo") {
                            Task { await viewModel.loadCoins() }
                        }
                    }
                } else {
                    List(filteredCoins) { coin in
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
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.addFavorite(coin)
                            } label: {
                                Label("Favoritar", systemImage: "heart.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                viewModel.removeFavorite(coin)
                            } label: {
                                Label("Remover", systemImage: "heart.slash.fill")
                            }
                            .tint(.red)
                        }
                    }
                    .searchable(text: $searchText)
                    .refreshable {
                        await viewModel.loadCoins()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    CoinListView(viewModel: CoinViewModel())
}
