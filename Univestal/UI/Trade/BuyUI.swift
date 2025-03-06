//
//  BuyUI.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/3/25.
//

import SwiftUI

struct BuyUI: View {
    let asset: Any // Can be Coin or Stock
    @State private var quantity: String = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var environment: TradingEnvironment
    @EnvironmentObject var finnhub: Finnhub
    
    // Validation Logic
    private func validateInput(_ input: String) -> Bool {
        // Don't allow empty string to be processed
        guard !input.isEmpty else { return true }
        
        // Only allow one decimal point
        let decimalCount = input.filter { $0 == "." }.count
        guard decimalCount <= 1 else { return false }
        
        // Prevent leading zeros without decimal
        if input.hasPrefix("00") { return false }
        
        // Only allow numbers and one decimal
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        let inputCharacters = CharacterSet(charactersIn: input)
        guard inputCharacters.isSubset(of: allowedCharacters) else { return false }
        
        // Limit to 8 characters
        guard input.count <= 8 else { return false }
        
        return true
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Buy \(assetName)")
                    .font(.largeTitle)
                    .padding()
                
                VStack() {
                    Text("Buying Power: \(environment.portfolioBalance.formatted(.currency(code: "USD")))")
                        .font(.title2)
                    
                    TextField("0", text: $quantity)
                        .font(.largeTitle)
                        .keyboardType(.decimalPad)
                        .onChange(of: quantity) {
                            if !validateInput(quantity) {
                                quantity = String(quantity.dropLast())
                            }
                        }
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                }
                
                Spacer()
                
                Button("Confirm Buy") {
                    if let coin = asset as? Coin {
                        let boughtQuantity = (coin.current_price / Double(quantity)!)
                        
                        do {
                            try environment.executeTrade(coinId: coin.name, symbol: coin.symbol, name: coin.name, quantity: boughtQuantity, currentPrice: coin.current_price)
                        } catch {
                            print("Failed to buy coin.")
                        }
                    } else if let stock = asset as? Stock {
                        let boughtQuantity = (stock.quote.currentPrice / Double(quantity)!)
                        
                        do {
                            try environment.executeStockTrade(symbol: stock.symbol, name: stock.lookup?.description ?? stock.symbol, quantity: boughtQuantity, currentPrice: stock.quote.currentPrice)
                        } catch {
                            print("Failed to buy stock.")
                        }
                    }
                    
                    dismiss()
                    
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
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
    
    private var assetName: String {
        if let coin = asset as? Coin {
            return coin.name
        } else if let stock = asset as? Stock {
            return stock.symbol
        }
        return ""
    }
}
