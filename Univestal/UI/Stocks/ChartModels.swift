//
//  ChartModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/10/25.
//

import SwiftUI
import Charts

struct StockInfoView: View {
    let stock: Stock
    
    private var change: Double {
        stock.quote.change ?? 0
    }
    
    private var formattedChange: (text: String, color: Color, symbol: String)? {
        guard let d = stock.quote.change else { return nil }
        let symbol = d >= 0 ? "▲" : "▼"
        return (String(format: "$%.2f (%.2f%%)", d, stock.quote.percentChange ?? 0), d >= 0 ? .green : .red, symbol)
    }
    
    private var progress: Double {
        let range = stock.quote.highPrice - stock.quote.lowPrice
        return (stock.quote.currentPrice - stock.quote.lowPrice) / range
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let desc = stock.lookup?.description {
                Text("\(desc) (\(stock.symbol.uppercased()))")
                    .font(.headline)
                    .bold()
            } else {
                Text(stock.symbol.uppercased())
                    .font(.headline)
                    .bold()
            }
            
            Text("Current Price: \(stock.quote.currentPrice, specifier: "$%.2f")")
                .font(.title2)
                .bold()
            
            if let changeInfo = formattedChange {
                HStack {
                    Text("\(changeInfo.symbol) \(changeInfo.text)")
                        .font(.subheadline)
                        .foregroundColor(changeInfo.color)
                }
            }
            
            metricsView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.primary)
                .opacity(0.07)
        )
    }
    
    private var metricsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading) {
                Text("Day Range: \(stock.quote.lowPrice, specifier: "$%.2f") - \(stock.quote.highPrice, specifier: "$%.2f")")
                    .font(.caption)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .padding(.vertical)
            
            
            if let metrics = stock.metrics {
                Text("52-week Range: \(metrics.fiftyTwoWeekLow ?? 0.0, specifier: "$%.2f") - \(metrics.fiftyTwoWeekHigh ?? 0.0, specifier: "$%.2f")")
                    .font(.caption)
                Text("Current Ratio: \(metrics.currentRatio ?? 0.0, specifier: "%.2f")")
                    .font(.caption)
                Text("Sales per Share: \(metrics.salesPerShare ?? 0.0, specifier: "%.2f")")
                    .font(.caption)
                Text("Net Margin: \(metrics.netMargin ?? 0.0, specifier: "%.2f")")
                    .font(.caption)
                Text("Beta: \(metrics.beta ?? 0.0, specifier: "%.2f")")
                    .font(.caption)
            }
            
        }
        .padding(.top, 4)
    }
}
