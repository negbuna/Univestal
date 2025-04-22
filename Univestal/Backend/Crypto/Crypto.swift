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
    @Published var coins: [Coin] = []
    @Published var detailedCoins: [Coin] = []
    var cancellables = Set<AnyCancellable>()
    private let apiKey = Config.cryptoKey

    // General coin data for searching
    func fetchCoins() async {
        guard await APIRequestManager.shared.canMakeCryptoRequest() else {
            // Use cached data if available
            if let cachedCoins = await CryptoCache.shared.getCachedCoins() {
                await MainActor.run {
                    self.coins = cachedCoins
                }
                return
            }
            return
        }
        
        // Try to get cached data first
        if let cachedCoins = await CryptoCache.shared.getCachedCoins() {
            await MainActor.run {
                self.coins = cachedCoins
            }
            return
        }
        
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=true&api_key=\(apiKey)") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedCoins = try JSONDecoder().decode([Coin].self, from: data)
            
            // Cache the new data
            await CryptoCache.shared.cacheCoins(decodedCoins)
            
            await MainActor.run {
                self.coins = decodedCoins
            }
        } catch {
            print("Error fetching coins: \(error)")
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
        
        // Try cache first with background refresh
        if let cached = await APICache.shared.value(
            type: endpoint.resourceType,
            key: endpoint.paginatedCacheKey
        ) { _ in
            try await client.send(endpoint)
        } {
            switch cached {
            case .fresh(let response), .stale(let response):
                return response
            }
        }
        
        return try await client.send(endpoint)
    }
    
    func searchCoins(query: String, page: Int = 1) async throws -> PaginatedResponse<Coin> {
        let endpoint = CoinGeckoEndpoint.Search(query: query, page: page)
        
        if let cached = await APICache.shared.value(
            type: endpoint.resourceType,
            key: endpoint.paginatedCacheKey
        ) { _ in
            try await client.send(endpoint)
        } {
            switch cached {
            case .fresh(let response), .stale(let response):
                return response
            }
        }
        
        return try await client.send(endpoint)
    }
}
