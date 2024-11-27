//
//  CoinDetailView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/27/24.
//

import SwiftUI

struct CoinDetailView: View {
    let coin: Coin

    var body: some View {
        ScrollView {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.primary)
                VStack(alignment: .leading, spacing: 16) {

                    Text("Symbol: \(coin.symbol.uppercased())")
                        .font(.headline)
                    Text("Current Price: \(coin.current_price, specifier: "%.2f") USD")
                    Text("Market Cap: \(coin.market_cap, specifier: "%.0f") USD")
                    Text("24h Volume: \(coin.total_volume, specifier: "%.0f") USD")
                    Text("24h High: \(coin.high_24h ?? 0, specifier: "%.2f") USD")
                    Text("24h Low: \(coin.low_24h ?? 0, specifier: "%.2f") USD")
                    Text("24h Price Change: \(coin.price_change_24h ?? 0, specifier: "%.2f") USD")

                    if let sparkline = coin.sparkline_in_7d?.price {
                        // Visualize sparkline or use it as needed
                        Text("Sparkline available (\(sparkline.count) points)")
                    } else {
                        Text("No sparkline data available.")
                    }
                } // end v
                
            }
            .padding()
        }
        .navigationTitle(coin.name)
    }
}
