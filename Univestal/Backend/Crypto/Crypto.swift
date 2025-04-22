//
//  Crypto.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import Combine
import Foundation

@MainActor
class Crypto: ObservableObject { // Fetching Coin data
    static let shared = Crypto()
    
    @Published var coins: [Coin] = []
    @Published var detailedCoins: [Coin] = []
    var cancellables = Set<AnyCancellable>()
    private let apiKey = Config.cryptoKey
    private let client = APIClient.shared

    private init() { } // Make init private for singleton

    // General coin data for searching
    func fetchCoins() async {
        print("🔄 Starting fetchCoins...")
        do {
            let endpoint = CoinGeckoEndpoint.MarketData(page: 1)
            print("🌐 Fetching fresh data from CoinGecko...")
            let coins = try await client.send(endpoint)
            print("✅ Received \(coins.count) coins from API")
            
            await MainActor.run {
                self.coins = coins
                print("📱 Updated UI with \(self.coins.count) coins")
            }
        } catch {
            print("❌ Error fetching coins: \(error)")
        }
    }
    
    // Specific coin data for coins in Watchlist
    func fetchDetailedCoins() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=true&price_change_percentage=24h") else {
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Coin].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error fetching detailed coins: \(error)")
                }
            }, receiveValue: { [weak self] detailedCoins in
                self?.detailedCoins = detailedCoins
            })
            .store(in: &cancellables)
    }
    
    func fetchMarketData(page: Int = 1) async throws -> PaginatedResponse<Coin> {
        let endpoint = CoinGeckoEndpoint.MarketData(page: page)
        let coins = try await client.send(endpoint)
        return PaginatedResponse(
            items: coins,
            page: page,
            totalItems: coins.count,
            itemsPerPage: endpoint.itemsPerPage
        )
    }
    
    func searchCoins(query: String, page: Int = 1) async throws -> PaginatedResponse<Coin> {
        let endpoint = CoinGeckoEndpoint.Search(query: query, page: page)
        return try await client.send(endpoint)
    }
}
