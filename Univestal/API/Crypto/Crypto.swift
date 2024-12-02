//
//  Crypto.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import Foundation
import Combine

class Crypto: ObservableObject { // Fetching Coin data
    @Published var coins: [Coin] = []
    @Published var detailedCoins: [Coin] = []
    private var cancellables = Set<AnyCancellable>()
    private let apiKey = Config.cryptoKey

    // General coin data for searching
    func fetchCoins() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false&api_key=\(apiKey)") else {
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url) // Making the network request w/ URL
            .map { $0.data } // Only extract data from dataTaskPublisher
            .decode(type: [Coin].self, decoder: JSONDecoder()) // Format data into Coin struct w/ JSONDecoder; will fail if JSONDecoder doesn't match up with Coin struct
            .receive(on: DispatchQueue.main) // To ensure UI updates are on main thread
            .sink( // Subscribe to publisher
                receiveCompletion: { completion in // Ensure request was received
                if case .failure(let error) = completion {
                    print("Error fetching coins: \(error)")
                }
            },  receiveValue: { [weak self] coins in // Ensures data was returned
                    self?.coins = coins
                }
            )
            .store(in: &cancellables) // Keep track of publisher subscriptions
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
