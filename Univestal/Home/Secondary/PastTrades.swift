//
//  PastTrades.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/14/24.
//

import SwiftUI
import CoreData

struct PastTrades: View {
    @EnvironmentObject var environment: TradingEnvironment
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDTrade.purchaseDate, ascending: false)],
        animation: .default
    )
    private var trades: FetchedResults<CDTrade>
    
    var body: some View {
        NavigationStack {
            VStack {
                if trades.isEmpty {
                    Text("No trades yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(trades, id: \.id) { trade in
                            TradeRowView(trade: trade)
                        }
                    }
                }
            }
            .navigationTitle("Trade History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        // Refresh prices from current crypto data
                        let prices = Dictionary(
                            uniqueKeysWithValues: environment.crypto.coins.map { 
                                ($0.id, $0.current_price) 
                            }
                        )
                        environment.updatePrices(with: prices)
                    }
                }
            }
        }
    }
}

struct TradeRowView: View {
    let trade: CDTrade
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trade.coinSymbol?.uppercased() ?? "Unknown")
                    .font(.headline)
                
                if let date = trade.purchaseDate {
                    Text(date, formatter: DateFormatter.shortDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formattedTradeValue)
                    .fontWeight(.bold)
                    .foregroundColor(tradeValueColor)
                
                if let profitLoss = profitLossValue {
                    Text(profitLoss)
                        .font(.caption)
                        .foregroundColor(profitLossColor)
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    private var formattedTradeValue: String {
        let totalValue = (trade.quantity) * (trade.currentPrice)
        return "$\(String(format: "%.2f", totalValue))"
    }
    
    private var profitLossValue: String? {
        guard trade.currentPrice > 0, trade.purchasePrice > 0 else { return nil }
        let pl = (trade.currentPrice - trade.purchasePrice) * trade.quantity
        let percentage = ((trade.currentPrice / trade.purchasePrice) - 1) * 100
        return String(format: "%+.2f (%.1f%%)", pl, percentage)
    }
    
    private var profitLossColor: Color {
        guard let pl = profitLossValue else { return .gray }
        return pl.hasPrefix("+") ? .green : .red
    }
    
    private var tradeValueColor: Color {
        guard trade.currentPrice > 0, trade.purchasePrice > 0 else { return .primary }
        return trade.currentPrice >= trade.purchasePrice ? .green : .red
    }
}

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    PastTrades()
        .environmentObject(TradingEnvironment.shared)
}
