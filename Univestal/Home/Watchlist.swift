//
//  Watchlist.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import SwiftUI

struct Watchlist: View {
    @ObservedObject var appData: AppData
    @ObservedObject var crypto: Crypto
    @State private var searchText = ""
    
    var filteredWatchlistCoins: [Coin] {
        let watchlistCoins = crypto.coins.filter { appData.watchlist.contains($0.id) }
        if searchText.isEmpty {
            return watchlistCoins
        } else {
            return watchlistCoins.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            if !appData.watchlist.isEmpty {
                List(filteredWatchlistCoins) { coin in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(coin.name)
                                .font(.headline)
                            Text(coin.symbol.uppercased())
                                .font(.subheadline)
                        }
                    }
                }
                .searchable(text: $searchText)
            } else {
                Text("Your watchlist is empty 😢")
            }
        }
        .navigationTitle("Watchlist")
    }
}
