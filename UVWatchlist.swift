//
//  UVWatchlist.swift
//  UV
//
//  Created by Nathan Egbuna on 8/3/24.
//

import SwiftUI

struct UVWatchlist: View {
    @EnvironmentObject var watchlist: Watchlist

    var body: some View {
        
        NavigationStack {
            
            if watchlist.coins.isEmpty {
                VStack {
                    Spacer()
                    VStack {
                        Text("You don't have any coins in your watchlist yet.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()

                        HStack {
                            NavigationLink(destination: UVSearch2().environmentObject(watchlist)) {
                                Text("Maybe you should add some...")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    Spacer()
                }
                .navigationTitle("Watchlist")
            } else {
                List(watchlist.coins, id: \.id) { coin in
                    NavigationLink(destination: DetailedCoinView(coin: coin)) {
                        VStack(alignment: .leading) {
                            Text(coin.name)
                                .font(.headline)
                            Text("Symbol: \(coin.symbol.uppercased())")
                                .font(.subheadline)
                            Text("Current Price: $\(coin.current_price, specifier: "%.2f")")
                                .font(.caption)
                            Text("24h Change: \(coin.price_change_percentage_24h, specifier: "%.2f")%")
                                .font(.caption)
                                .foregroundColor(coin.price_change_percentage_24h >= 0 ? .green : .red)
                        }
                    }
                }
                .navigationTitle("Watchlist")
            }
        }
    }
}


#Preview {
    UVWatchlist()
        .environmentObject(Watchlist())
}
