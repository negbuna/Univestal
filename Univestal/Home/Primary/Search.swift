//
//  Search.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import SwiftUI

struct Search: View {
    @ObservedObject var appData: AppData
    @ObservedObject var crypto: Crypto
    @State private var searchText = ""
    @State private var selectedCoinID: String? = nil

    var filteredCoins: [Coin] {
        if searchText.isEmpty {
            return crypto.coins
        } else {
            return crypto.coins.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var selectedCoin: Coin? {
        crypto.coins.first { $0.id == selectedCoinID }
    }

    var body: some View {
        NavigationStack {
            List(filteredCoins) { coin in
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
                    
                    VStack(alignment: .trailing) {
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
            .navigationTitle("Coins")
            .onAppear {
                crypto.fetchCoins()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: Watchlist(appData: appData, crypto: crypto)) {
                        Text("Watchlist")
                    }
                }
            }
            .navigationDestination(isPresented: .constant(selectedCoinID != nil)) {
                if let coin = selectedCoin {
                    CoinDetailView(appData: appData, coin: coin)
                }
            }
        }
    }
}

#Preview {
    Search(appData: AppData(), crypto: Crypto())
}
