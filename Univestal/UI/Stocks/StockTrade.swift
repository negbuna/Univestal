//
//  StockTrade.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/28/25.
//

import SwiftUI

struct StockTradingView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @EnvironmentObject var finnhub: Finnhub
    @State private var showMenu = false
    @State private var selectedStock: Stock?
    @State private var quantity = ""
    @State private var isBuying = true
    @State private var showAlert = false
    @State private var alertType: TradeAlertType?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let stock = selectedStock {
                    VStack(spacing: 12) {
                        Text(stock.symbol)
                            .font(.headline)
                        Text("$\(stock.quote.currentPrice, specifier: "%.2f")")
                            .font(.title2)
                        
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        
                        if let qty = Double(quantity) {
                            Text("Total: $\(qty * stock.quote.currentPrice, specifier: "%.2f")")
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
                case .confirmTrade:
                    Alert(
                        title: Text("Confirm Trade"),
                        message: Text("Are you sure you want to execute this trade?"),
                        primaryButton: .default(Text("Confirm")) {
                            executeStockTrade()
                        },
                        secondaryButton: .cancel()
                    )
                }
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
                    name: stock.lookup?.description ?? stock.symbol,
                    quantity: quantity,
                    currentPrice: stock.quote.currentPrice
                )
            } else {
                try environment.executeStockSell(
                    symbol: stock.symbol,
                    name: stock.lookup?.description ?? stock.symbol,
                    quantity: quantity,
                    currentPrice: stock.quote.currentPrice
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
        .environmentObject(Finnhub())
}
