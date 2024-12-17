//
//  CoinDetailView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/27/24.
//

import SwiftUI

struct CoinDetailView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    let coin: Coin
     
    var body: some View {
        ScrollView {
            ZStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Symbol: \(coin.symbol.uppercased())")
                        .font(.headline)
                    Text("Current Price: \(coin.current_price, specifier: "%.2f") USD")
                    Text("Market Cap: \(appData.formatLargeNumber(coin.market_cap)) USD")
                    Text("24h Volume: \(appData.formatLargeNumber(coin.total_volume)) USD")
                    Text("24h High: \(coin.high_24h ?? 0, specifier: "%.2f") USD")
                    Text("24h Low: \(coin.low_24h ?? 0, specifier: "%.2f") USD")
                    Text("24h Price Change: \(coin.price_change_24h ?? 0, specifier: "%.2f") USD")

                    if let sparkline = coin.sparkline_in_7d?.price {
                        Text("Sparkline available (\(sparkline.count) points)")
                    } else {
                        Text("Sparkline data is currently unavailable")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(.primary)
                    .opacity(0.07)
                )
            }
        }
        .navigationTitle(coin.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    appData.toggleWatchlist(for: coin.id)
                }) {
                    Image(systemName: appData.watchlist.contains(coin.id) ? "star.fill" : "star")
                        .foregroundColor(appData.watchlist.contains(coin.id) ? .yellow : .gray)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CoinDetailView(coin: Coin.example)
            .environmentObject(AppData())
            .environmentObject(TradingEnvironment.shared)
    }
}

extension Coin {
    static var example: Coin {
        Coin(
            name: "bitcoin",
            symbol: "btc",
            id: "Bitcoin",
            current_price: 45000.0,
            market_cap: 850000000000,
            total_volume: 25000000000,
            high_24h: 46000.0,
            low_24h: 44000.0,
            price_change_24h: 1000.0,
            price_change_percentage_24h: 2.5,
            image: nil,
            sparkline_in_7d: nil
        )
    }
}
