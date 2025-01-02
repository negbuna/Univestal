//
//  CoinDetailView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/27/24.
//

import SwiftUI
import Charts

struct CoinDetailView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    let coin: Coin
    
    private var chartYAxisRange: ClosedRange<Double> {
        let maxPrice = coin.current_price * 1.05
        let minPrice = coin.current_price * 0.95
        
        // For very stable coins, ensure minimum range
        let range = maxPrice - minPrice
        if range < (coin.current_price * 0.02) {  // If range is less than 2%
            return (coin.current_price * 0.99)...(coin.current_price * 1.01)
        }
        
        return minPrice...maxPrice
    }
    
    private func priceColor(current: Double, previous: Double) -> Color {
        current >= previous ? .green : .red
    }
    
    private var formattedMarketCap: String {
        appData.formatLargeNumber(coin.market_cap)
    }
        
    private var formattedVolume: String {
        appData.formatLargeNumber(coin.total_volume)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Symbol: \(coin.symbol.uppercased())")
                            .font(.headline)
                        Text("Current Price: \(coin.current_price < 0.01 ? String(format: "$%.7f", coin.current_price) : String(format: "$%.2f", coin.current_price))")
                        Text("Market Cap: \(formattedMarketCap)")
                        Text("24h Volume: \(formattedVolume)")
                        Text("24h High: \(coin.high_24h ?? 0, specifier: "$%.2f")")
                        Text("24h Low: \(coin.low_24h ?? 0, specifier: "$%.2f")")
                        Text("24h Price Change: \(coin.price_change_24h ?? 0, specifier: "$%.2f")")
                        
                        if let sparkline = coin.sparkline_in_7d?.price {
                            Text("Sparkline available (\(sparkline.count) points)")
                        } else {
                            Text("Sparkline data is currently unavailable")
                        }
                        
                        if let sparklineData = coin.sparkline_in_7d?.price {
                            VStack(alignment: .leading) {
                                Text("7 Day Price History")
                                    .font(.headline)
                                
                                Chart {
                                    ForEach(Array(sparklineData.enumerated()), id: \.offset) { index, price in
                                        if index > 0 {
                                            LineMark(
                                                x: .value("Time", index),
                                                y: .value("Price", price)
                                            )
                                            .foregroundStyle(priceColor(current: price, previous: sparklineData[index - 1]))
                                        }
                                    }
                                }
                                .chartXAxis(.hidden)
                                .chartYAxis {
                                    AxisMarks(position: .trailing)
                                }
                                .chartYScale(domain: chartYAxisRange)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(.primary)
                                    .opacity(0.07)
                            )
                        }
                    }
                    .padding(30)
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
            .globeOverlay()
        } // nav stack
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
            name: "Bitcoin",
            symbol: "btc",
            id: "Bitcoin",
            current_price: 97000.0,
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
