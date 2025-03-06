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
    @EnvironmentObject var finnhub: Finnhub
    @Environment(\.dismiss) private var dismiss
    
    private var trades: [CDTrade] {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDTrade.purchaseDate, ascending: false)]
        return (try? environment.coreDataStack.context.fetch(fetchRequest)) ?? []
    }
    
    private var stockTrades: [StockTrade] {
        let fetchRequest: NSFetchRequest<StockTrade> = StockTrade.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \StockTrade.purchaseDate, ascending: false)]
        return (try? environment.coreDataStack.context.fetch(fetchRequest)) ?? []
    }
    
    private var allTrades: [TradeDisplayItem] {
        let cryptoTrades = trades.map { TradeDisplayItem(trade: $0) }
        let stockTrades = stockTrades.map { TradeDisplayItem(stockTrade: $0) }
        return (cryptoTrades + stockTrades).sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allTrades) { item in
                    TradeRowView(item: item)
                }
            }
            .navigationTitle("Trade History")
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
            }
        }
    }
}

struct TradeRowView: View {
    let item: TradeDisplayItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(abs(item.quantity), specifier: "%.3f") \(item.symbol.uppercased())")
                        .font(.headline)
                    
                    Spacer()
                    
                    let amount = item.purchasePrice * abs(item.quantity)
                    Text("\(item.quantity > 0 ? "-" : "+")\(amount, specifier: "$%.2f")")
                        .fontWeight(.bold)
                        .foregroundColor(item.quantity > 0 ? .red : .green)
                }
                
                Text(item.date, formatter: DateFormatter.shortDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.quantity < 0 ? "SELL" : "BUY")
                    .font(.caption)
                    .foregroundColor(item.quantity < 0 ? .green : .red)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 2.5).fill(item.quantity < 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2)))
            }
        }
    }
}

struct TradeDisplayItem: Identifiable {
    let id: UUID
    let symbol: String
    let name: String
    let quantity: Double
    let purchasePrice: Double
    let currentPrice: Double
    let date: Date
    let isStock: Bool
    
    init(trade: CDTrade) {
        self.id = trade.id ?? UUID()
        self.symbol = trade.coinSymbol ?? ""
        self.name = trade.coinName ?? ""
        self.quantity = trade.quantity
        self.purchasePrice = trade.purchasePrice
        self.currentPrice = trade.currentPrice
        self.date = trade.purchaseDate ?? Date()
        self.isStock = false
    }
    
    init(stockTrade: StockTrade) {
        self.id = stockTrade.id ?? UUID()
        self.symbol = stockTrade.symbol ?? ""
        self.name = stockTrade.name ?? ""
        self.quantity = stockTrade.quantity
        self.purchasePrice = stockTrade.purchasePrice
        self.currentPrice = stockTrade.currentPrice
        self.date = stockTrade.purchaseDate ?? Date()
        self.isStock = true
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
        .environmentObject(Finnhub())
}
