//
//  StockTrade.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/28/25.
//

import SwiftUI

enum TradeAlertType: Identifiable {
    case insufficientFunds, insufficientHoldings, tradeError
    
    var id: String { UUID().uuidString }
}

struct StockTradingView: View {
    @EnvironmentObject var environment: TradingEnvironment
    @State private var showMenu = false
    @State private var selectedStock: Stock?
    @State private var quantity = ""
    @State private var isBuying = true
    @State private var showAlert = false
    @State private var alertType: TradeAlertType?
    
    var body: some View {
        VStack {
            if let stock = selectedStock {
                VStack(spacing: 12) {
                    Text(stock.name)
                        .font(.headline)
                    Text("$\(stock.price, specifier: "%.2f")")
                        .font(.title2)
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    
                    if let qty = Double(quantity) {
                        Text("Total: $\(qty * stock.price, specifier: "%.2f")")
                    }
                    
                    HStack {
                        Button("Buy") {
                            isBuying = true
                            executeStockTrade()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Sell") {
                            isBuying = false
                            executeStockTrade()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
        }
        .alert(item: $alertType) { type in
            switch type {
            case .insufficientFunds:
                Alert(title: Text("Insufficient Funds"))
            case .insufficientHoldings:
                Alert(title: Text("Insufficient Holdings"))
            case .tradeError:
                Alert(title: Text("Trade Error"))
            }
        }
    }
    
    private func executeStockTrade() {
        guard let stock = selectedStock,
              let quantity = Double(quantity) else {
            return
        }
        
        do {
            if isBuying {
                try environment.executeStockTrade(
                    symbol: stock.symbol,
                    name: stock.name,
                    quantity: quantity,
                    currentPrice: stock.price
                )
            } else {
                try environment.executeStockSell(
                    symbol: stock.symbol,
                    name: stock.name,
                    quantity: quantity,
                    currentPrice: stock.price
                )
            }
            self.quantity = ""
            self.selectedStock = nil
        } catch {
            alertType = .tradeError
        }
    }
}

#Preview {
    StockTradingView()
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(AppData())
    
}
