import Foundation

enum CoinServiceError: LocalizedError {
    case invalidURL
    case emptyResponse
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .emptyResponse:
            return "A resposta do servidor veio vazia."
        case .rateLimited:
            return "Muitas requisições em pouco tempo. Espera um instante e tenta de novo."
        case .serverError(let code):
            return "O servidor respondeu com erro (\(code))."
        }
    }
}

private struct MarketChartResponse: Decodable {
    let prices: [[Double]]
}

private actor HistoryCache {
    static let shared = HistoryCache()
    private var entries: [String: (points: [PricePoint], timestamp: Date)] = [:]
    private let ttl: TimeInterval = 60

    func get(_ key: String) -> [PricePoint]? {
        guard let entry = entries[key], Date().timeIntervalSince(entry.timestamp) < ttl else {
            return nil
        }
        return entry.points
    }

    func set(_ key: String, points: [PricePoint]) {
        entries[key] = (points, Date())
    }
}

private actor CoinsCache {
    static let shared = CoinsCache()
    private var cached: (coins: [Coin], timestamp: Date)?
    private let ttl: TimeInterval = 30

    func get() -> [Coin]? {
        guard let cached, Date().timeIntervalSince(cached.timestamp) < ttl else { return nil }
        return cached.coins
    }

    func set(_ coins: [Coin]) {
        cached = (coins, Date())
    }
}

struct CoinService {

    private func validate(_ response: URLResponse, context: String, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        print("[CoinService] \(context) status=\(http.statusCode) bytes=\(data.count)")

        if http.statusCode == 429 {
            print("[CoinService] \(context) RATE LIMITED (429): \(String(data: data, encoding: .utf8) ?? "")")
            throw CoinServiceError.rateLimited
        }
        guard (200...299).contains(http.statusCode) else {
            print("[CoinService] \(context) erro HTTP \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
            throw CoinServiceError.serverError(http.statusCode)
        }
    }

    func fetchCoins() async throws -> [Coin] {
        if let cached = await CoinsCache.shared.get() {
            print("[CoinService] fetchCoins → cache HIT (\(cached.count) moedas)")
            return cached
        }

        guard let url = URL(string:"https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1") else {
            throw CoinServiceError.invalidURL
        }

        print("[CoinService] fetchCoins → cache MISS, iniciando chamada")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response, context: "fetchCoins", data: data)

        guard !data.isEmpty else {
            throw CoinServiceError.emptyResponse
        }

        let decoder = JSONDecoder()
        do {
            let coins = try decoder.decode([Coin].self, from: data)
            print("[CoinService] fetchCoins → sucesso, \(coins.count) moedas")
            await CoinsCache.shared.set(coins)
            return coins
        } catch {
            print("[CoinService] fetchCoins → erro de decode: \(error)")
            throw error
        }
    }

    func fetchPriceHistory(coinID: String, days: Int = 7) async throws -> [PricePoint] {
        let cacheKey = "\(coinID)_\(days)"
        if let cached = await HistoryCache.shared.get(cacheKey) {
            print("[CoinService] fetchPriceHistory(\(coinID), days=\(days)) → cache HIT (\(cached.count) pontos)")
            return cached
        }

        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coinID)/market_chart?vs_currency=usd&days=\(days)") else {
            throw CoinServiceError.invalidURL
        }

        print("[CoinService] fetchPriceHistory(\(coinID), days=\(days)) → cache MISS, iniciando chamada")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response, context: "fetchPriceHistory(\(coinID))", data: data)

        guard !data.isEmpty else {
            throw CoinServiceError.emptyResponse
        }

        let decoder = JSONDecoder()
        do {
            let parsed = try decoder.decode(MarketChartResponse.self, from: data)
            let points = parsed.prices.compactMap { pair -> PricePoint? in
                guard pair.count == 2 else { return nil }
                return PricePoint(date: Date(timeIntervalSince1970: pair[0] / 1000), price: pair[1])
            }
            print("[CoinService] fetchPriceHistory(\(coinID)) → sucesso, \(points.count) pontos")
            await HistoryCache.shared.set(cacheKey, points: points)
            return points
        } catch {
            print("[CoinService] fetchPriceHistory(\(coinID)) → erro de decode: \(error)")
            throw error
        }
    }
}
