import Foundation

@Observable
class CoinDetailViewModel {
    var pricePoints: [PricePoint] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let coinService = CoinService()
    private var currentRequestID = UUID()

    func loadHistory(coinID: String, days: Int = 7) async {
        let requestID = UUID()
        currentRequestID = requestID
        print("[CoinDetailViewModel] loadHistory(\(coinID), days=\(days)) chamado — requestID=\(requestID)")

        let hadData = !pricePoints.isEmpty
        if !hadData {
            isLoading = true
            errorMessage = nil
        }

        do {
            let points = try await coinService.fetchPriceHistory(coinID: coinID, days: days)
            guard requestID == currentRequestID else {
                print("[CoinDetailViewModel] resultado descartado (requestID antigo) coin=\(coinID)")
                return
            }
            pricePoints = points
            errorMessage = nil
            print("[CoinDetailViewModel] loadHistory sucesso coin=\(coinID) pontos=\(points.count)")
        } catch {
            guard requestID == currentRequestID else {
                print("[CoinDetailViewModel] erro descartado (requestID antigo) coin=\(coinID)")
                return
            }
            print("[CoinDetailViewModel] loadHistory falhou coin=\(coinID) hadData=\(hadData) erro=\(error)")
            if !hadData {
                errorMessage = error.localizedDescription
            }
        }

        guard requestID == currentRequestID else { return }
        isLoading = false
    }
}
