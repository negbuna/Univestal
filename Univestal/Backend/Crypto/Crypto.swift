//
//  Crypto.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import Combine
import Foundation

class Crypto: ObservableObject { // Fetching Coin data
    @Published var coins: [Coin] = []
    @Published var detailedCoins: [Coin] = []
    var cancellables = Set<AnyCancellable>()
    private let apiKey = Config.cryptoKey

    // General coin data for searching
    func fetchCoins() async {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=true&api_key=\(apiKey)") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedCoins = try JSONDecoder().decode([Coin].self, from: data)
            
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
}
