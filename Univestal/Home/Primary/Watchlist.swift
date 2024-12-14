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
    @State private var selectedCoinID: String? = nil

    var filteredWatchlistCoins: [Coin] {
        let watchlistCoins = crypto.coins.filter { appData.watchlist.contains($0.id) }
        if searchText.isEmpty {
            return watchlistCoins
        } else {
            return watchlistCoins.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var selectedCoin: Coin? {
        crypto.coins.first { $0.id == selectedCoinID }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if !appData.watchlist.isEmpty {
                    List(filteredWatchlistCoins) { coin in
                        HStack {
                            Button(action: {
                                appData.toggleWatchlist(for: coin.id)
                            }) {
                                Image(systemName: appData.watchlist.contains(coin.id) ? "star.fill" : "star")
                                    .foregroundColor(appData.watchlist.contains(coin.id) ? .yellow : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // So button taps are not intercepted
                            
                            VStack(alignment: .leading) {
                                Text(coin.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(coin.symbol.uppercased())
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text(String(format: "%.2f", coin.current_price))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(String(format: "%.2f%%", coin.price_change_percentage_24h ?? 0.00))
                                    .font(.subheadline)
                                    .foregroundColor(appData.percentColor(coin.price_change_percentage_24h ?? 0))
                            }
                        }
                        .contentShape(Rectangle()) // Keeps row tappable for gestures
                        .onTapGesture {
                            selectedCoinID = coin.id
                        }
                    }
                    .searchable(text: $searchText)
                    .navigationDestination(isPresented: .constant(selectedCoinID != nil)) {
                        if let coin = selectedCoin {
                            CoinDetailView(appData: appData, coin: coin)
                        }
                    }
                } else {
                    Text("Your watchlist is empty 😢")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: Search(appData: appData, crypto: crypto)) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Watchlist") // Make sure this is inside NavigationStack
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    Watchlist(appData: AppData(), crypto: Crypto())
}
