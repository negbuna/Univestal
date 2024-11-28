//
//  CoinDetailView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/27/24.
//

import SwiftUI

struct CoinDetailView: View {
    @ObservedObject var appData: AppData
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
                        // Visualize sparkline
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
    }
}
