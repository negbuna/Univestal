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
    
    private var trades: [CDTrade] {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDTrade.purchaseDate, ascending: false)]
        return (try? environment.coreDataStack.context.fetch(fetchRequest)) ?? []
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if trades.isEmpty {
                    Text("No trades yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(trades) { trade in
                            TradeRowView(trade: trade)
                        }
                    }
                }
            }
            .navigationTitle("Trade History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let prices = Dictionary(
                            uniqueKeysWithValues: environment.crypto.coins.map {
                                ($0.id, $0.current_price)
                            }
                        )
                        environment.updatePrices(with: prices)
                    } label: {
                        Image(systemName: "arrow.clockwise")
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
                HStack {
                    Text("\(abs(trade.quantity), specifier: "%.3f") \(trade.coinSymbol?.uppercased() ?? "Unknown")")
                        .font(.headline)
                    
                    Spacer()
                    
                    let amount = trade.purchasePrice * trade.quantity
                    Text("\(amount, specifier: "$%.2f")")
                        .fontWeight(.bold)
                        .foregroundColor(amount < 0 ? .red : .green)
                }
                
                Text(trade.quantity < 0 ? "SELL" : "BUY")
                    .font(.caption)
                    .foregroundColor(trade.quantity < 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(trade.quantity < 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    )
                
                if let date = trade.purchaseDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let profitLoss = calculateProfitLoss() {
                    Text(profitLoss)
                        .font(.caption)
                        .foregroundColor(profitLossColor)
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    private func calculateProfitLoss() -> String? {
        guard trade.currentPrice > 0, trade.purchasePrice > 0 else { return nil }
        let pl = (trade.currentPrice - trade.purchasePrice) * trade.quantity
        let percentage = ((trade.currentPrice / trade.purchasePrice) - 1) * 100
        return String(format: "%+.2f (%.1f%%)", pl, percentage)
    }
    
    private var profitLossColor: Color {
        guard let pl = calculateProfitLoss() else { return .gray }
        return pl.hasPrefix("+") ? .green : .red
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
