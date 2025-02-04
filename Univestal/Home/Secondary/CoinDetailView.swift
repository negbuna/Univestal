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
    @Environment(\.dismiss) private var dismiss
    
    let coin: Coin 
    @State private var selectedPrice: Double?
    @State private var selectedIndex: Int?
    @State private var showTooltip = false
    @State private var tooltipPosition: CGPoint = .zero
    
    private var chartYAxisRange: ClosedRange<Double> {
        guard let sparklineData = coin.sparkline_in_7d?.price, !sparklineData.isEmpty else {
            return 0...1 // Fallback range
        }
        
        // Find actual min and max
        let maxPrice = sparklineData.max() ?? coin.current_price
        let minPrice = sparklineData.min() ?? coin.current_price
        
        // Calculate price range and padding
        let priceRange = maxPrice - minPrice
        let rangePadding = priceRange * 0.05 // 5% padding
        
        // For very small ranges (stable prices), use percentage-based range
        if priceRange < (coin.current_price * 0.005) { // If range is less than 0.5%
            let basePrice = coin.current_price
            return (basePrice * 0.9975)...(basePrice * 1.0025) // ±0.25% range
        }
        
        // For normal ranges, add padding to min/max
        return (minPrice - rangePadding)...(maxPrice + rangePadding)
    }
    
    private func priceColor(current: Double, previous: Double) -> Color {
        current >= previous ? .green : .red
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price < 0.01 {
            return String(format: "%.7f", price)
        } else if price < 1 {
            return String(format: "%.5f", price)
        } else {
            return String(format: "%.2f", price)
        }
    }
    
    private func formattedDate(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .hour, value: -index, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
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
                            Text("Sparkline data is currently unavailable for this coin.")
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
                                    
                                    if let selectedIndex = selectedIndex,
                                       let selectedPrice = selectedPrice {
                                        RuleMark(
                                            x: .value("Selected", selectedIndex)
                                        )
                                        .foregroundStyle(.gray.opacity(0.3))
                                        
                                        PointMark(
                                            x: .value("Selected", selectedIndex),
                                            y: .value("Price", selectedPrice)
                                        )
                                        .foregroundStyle(.blue)
                                    }
                                }
                                .frame(height: 200)
                                .chartXAxis(.hidden)
                                .chartYAxis {
                                    AxisMarks(position: .trailing) { value in
                                        let price = value.as(Double.self) ?? 0
                                        AxisValueLabel {
                                            Text(formatPrice(price))
                                        }
                                    }
                                }
                                .chartYScale(domain: chartYAxisRange)
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        Rectangle().fill(.clear).contentShape(Rectangle())
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let x = value.location.x - geometry.frame(in: .local).origin.x
                                                        if let index = proxy.value(atX: x) as Int?,
                                                           index >= 0 && index < sparklineData.count {
                                                            selectedIndex = index
                                                            selectedPrice = sparklineData[index]
                                                            tooltipPosition = value.location
                                                            showTooltip = true
                                                        }
                                                    }
                                                    .onEnded { _ in
                                                        selectedIndex = nil
                                                        selectedPrice = nil
                                                        showTooltip = false
                                                    }
                                            )
                                    }
                                    .overlay {
                                        if showTooltip,
                                           let index = selectedIndex,
                                           let price = selectedPrice {
                                            let date = Calendar.current.date(byAdding: .hour,
                                                                          value: -index,
                                                                          to: Date()) ?? Date()
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(formatDate(date))
                                                    .font(.caption)
                                                Text("$\(formatPrice(price))")
                                                    .font(.caption.bold())
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(UIColor.systemBackground))
                                                    .shadow(radius: 4)
                                            )
                                            .position(x: tooltipPosition.x, y: tooltipPosition.y - 50)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(.primary)
                                    .opacity(0.07)
                            )
                        }
                        
                        HStack {
                            NavigationLink(destination: BuyUI(asset: coin)) {
                                Text("Buy")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                            
                            NavigationLink(destination: SellUI(asset: coin)) {
                                Text("Sell")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(15)
                            }
                        }
                        .padding()
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        CoinDetailView(coin: Coin.example)
            .environmentObject(AppData())
            .environmentObject(TradingEnvironment.shared)
            .navigationBarBackButtonHidden(true)
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
