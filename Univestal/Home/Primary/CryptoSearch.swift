//
//  CryptoSearch.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import SwiftUI

struct CryptoSearch: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @Binding var searchText: String
    @State private var selectedCoinID: String? = nil
    @State private var isLoading = true

    var filteredCoins: [Coin] {
        if searchText.isEmpty {
            return environment.crypto.coins
        } else {
            let results = environment.crypto.coins.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            return results.isEmpty ? [] : results // Return empty array if no results
        }
    }

    var selectedCoin: Coin? {
        environment.crypto.coins.first { $0.id == selectedCoinID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else if filteredCoins.isEmpty {
                    VStack {
                        Spacer()
                        Text("No results")
                            .font(.headline)
                            .foregroundStyle(.gray)
                            .padding()
                        Spacer()
                    }
                } else {
                    List(filteredCoins) { coin in
                        HStack {
                            Button(action: {
                                appData.toggleWatchlist(for: coin.id)
                            }) {
                                Image(systemName: appData.watchlist.contains(coin.id) ? "star.fill" : "star")
                                    .foregroundColor(appData.watchlist.contains(coin.id) ? .yellow : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // So button taps are not intercepted
                            
                            NavigationLink(destination: CoinDetailView(coin: coin)) {
                                HStack {
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
                                        Text(String(format: "$%.2f", coin.current_price))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(String(format: "%.2f%%", coin.price_change_percentage_24h ?? 0.00))
                                            .font(.subheadline)
                                            .foregroundColor(appData.percentColor(coin.price_change_percentage_24h ?? 0))
                                    }
                                }
                            }
                        }
                    }
                }
            }
//            .navigationTitle("Coins")
//            .navigationBarTitleDisplayMode(.inline)
            .task {
                if environment.crypto.coins.isEmpty {
                    await environment.crypto.fetchCoins()
                }
                isLoading = false
            }
            .searchable(text: $searchText)
        }
    }
}

//#Preview {
//    CryptoSearch()
//        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
//        .environmentObject(TradingEnvironment.shared)
//}
