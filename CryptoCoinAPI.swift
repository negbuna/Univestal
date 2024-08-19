import Foundation

func fetchCoins() async throws {
    
    guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: path),
          let apiKey = config["CG_API_KEY"] as? String else {
        print("Failed to load API key from Config.plist")
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load API key"])
    }
    
    let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets")!
    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
    let queryItems: [URLQueryItem] = [
        URLQueryItem(name: "order", value: "market_cap_desc"),
        URLQueryItem(name: "per_page", value: "250"),
        URLQueryItem(name: "page", value: "1"),
        URLQueryItem(name: "sparkline", value: "true"),
        URLQueryItem(name: "price_change_percentage", value: "24h"),
        URLQueryItem(name: "locale", value: "en"),
        URLQueryItem(name: "precision", value: "2")
    ]
    components.queryItems = queryItems

    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.timeoutInterval = 10
    request.allHTTPHeaderFields = [
        "accept": "application/json",
        "x-cg-demo-api-key": apiKey
    ]

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        print(String(decoding: data, as: UTF8.self))
    } catch {
        print("Error fetching coins: \(error)")
    }
}
