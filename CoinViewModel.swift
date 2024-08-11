//
//  CoinViewModel.swift
//  UV
//
//  Created by Nathan Egbuna on 8/1/24.
//

import Foundation
import Combine

struct Coin: Identifiable, Codable {
    let id: String
    let name: String
    let symbol: String
    let current_price: Double
    let market_cap: Double
    let price_change_percentage_24h: Double
    let sparkline_in_7d: Sparkline?

    struct Sparkline: Codable {
        let price: [Double]
    }
}

struct CryptoIdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

class CoinViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    @Published var errorMessage: IdentifiableError? = nil
    @Published var searchText: String = ""
    
    var filteredCoins: [Coin] {
        if searchText.isEmpty {
            return coins
        } else {
            return coins.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.symbol.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func fetchCoins() {
        Task {
            do {
                try await fetchCoinsAsync()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = IdentifiableError(message: error.localizedDescription)
                }
            }
        }
    }
    
    func fetchCoinsAsync() async throws {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["CG_API_KEY"] as? String else {
            print("Failed to load API key from Config.plist")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load API key"])
        }
        
        let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "order", value: "market_cap_desc"),
            URLQueryItem(name: "per_page", value: "250"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "sparkline", value: "true"),
            URLQueryItem(name: "price_change_percentage", value: "24h"),
            URLQueryItem(name: "locale", value: "en"),
            URLQueryItem(name: "precision", value: "2"),
        ]
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-cg-demo-api-key": apiKey
        ]
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Debug: Print raw data
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let coins = try decoder.decode([Coin].self, from: data)
        DispatchQueue.main.async {
            self.coins = coins
        }
    }
}
