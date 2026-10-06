import SwiftUI
import Charts

struct CoinDetailView: View {
    let coin: Coin
    var coinViewModel: CoinViewModel
    @State private var viewModel = CoinDetailViewModel()
    @State private var selectedRange: TimeRange = .week
    @State private var debounceTask: Task<Void, Never>?
    @State private var targetPriceText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    AsyncImage(url: URL(string: coin.image)) { image in
                        image.resizable()
                    } placeholder: {
                        Circle().fill(.secondary.opacity(0.2))
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(coin.name)
                            .font(.title2.bold())
                        Text(coin.symbol.uppercased())
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(coin.currentPrice, format: .currency(code: "USD"))
                        .font(.title3.bold())
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    Text("Erro: \(error)")
                        .foregroundStyle(.red)
                } else if viewModel.pricePoints.isEmpty {
                    Text("Sem histórico disponível.")
                        .foregroundStyle(.secondary)
                } else {
                    let prices = viewModel.pricePoints.map(\.price)
                    let minPrice = prices.min() ?? 0
                    let maxPrice = prices.max() ?? 0
                    let padding = (maxPrice - minPrice) * 0.1

                    Chart(viewModel.pricePoints) { point in
                        LineMark(
                            x: .value("Data", point.date),
                            y: .value("Preço", point.price)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: (minPrice - padding)...(maxPrice + padding))
                    .frame(height: 220)
                }

                Picker("Período", selection: $selectedRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                alertSection
            }
            .padding()
        }
        .navigationTitle(coin.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            print("[CoinDetailView] .task — entrou na tela de \(coin.name) (\(coin.id)), período inicial \(selectedRange.rawValue)")
            await viewModel.loadHistory(coinID: coin.id, days: selectedRange.days)
        }
        .onChange(of: selectedRange) {
            print("[CoinDetailView] período selecionado \(selectedRange.rawValue) em \(coin.name) — aguardando debounce")
            debounceTask?.cancel()
            let rangeAtRequestTime = selectedRange
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else {
                    print("[CoinDetailView] debounce cancelado (trocou de novo antes de disparar) — \(rangeAtRequestTime.rawValue) descartado")
                    return
                }
                print("[CoinDetailView] debounce concluído, disparando chamada pra \(rangeAtRequestTime.rawValue)")
                await viewModel.loadHistory(coinID: coin.id, days: rangeAtRequestTime.days)
            }
        }
    }

    private var parsedTarget: Double? {
        Double(targetPriceText.replacingOccurrences(of: ",", with: "."))
    }

    @ViewBuilder
    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.orange)
                Text("Alerta de preço")
                    .font(.headline)
            }

            if let existing = coinViewModel.alert(for: coin) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.orange, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avisar quando chegar em")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(existing.targetPrice, format: .currency(code: "USD"))
                            .font(.title3.bold())
                    }

                    Spacer()

                    Button {
                        coinViewModel.removeAlert(for: coin)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $targetPriceText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("targetPriceField")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))

                    Button {
                        guard let target = parsedTarget else { return }
                        Task {
                            await coinViewModel.setAlert(for: coin, targetPrice: target)
                            targetPriceText = ""
                        }
                    } label: {
                        Text("Definir")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(parsedTarget == nil)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        CoinDetailView(
            coin: Coin(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                image: "",
                currentPrice: 62000,
                priceChangePercentage24h: 2.5
            ),
            coinViewModel: CoinViewModel()
        )
    }
}
