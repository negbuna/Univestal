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
                    VStack(alignment: .leading) {
                        Text(coin.name)
                            .font(.headline)
                        Text(coin.symbol.uppercased())
                            .font(.subheadline)
                    }

                    Spacer()

                    // Star button to add/remove from watchlist
                    Button(action: {
                        appData.toggleWatchlist(for: coin.id)
                    }) {
                        Image(systemName: appData.watchlist.contains(coin.id) ? "star.fill" : "star")
                            .foregroundColor(appData.watchlist.contains(coin.id) ? .yellow : .gray)
                    }
                }
                .contentShape(Rectangle()) // Makes the whole row tappable
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UVSettingsView(appData: appData)) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .navigationDestination(isPresented: .constant(selectedCoinID != nil)) {
                if let coin = selectedCoin {
                    CoinDetailView(coin: coin)
                }
            }
        }
    }
}

#Preview {
    Search(appData: AppData(), crypto: Crypto())
}
