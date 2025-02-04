//
//  SellUI.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/3/25.
//

import SwiftUI

struct SellUI: View {
    let asset: Any
    @State private var quantity: String = ""
    @Environment(\.dismiss) private var dismiss
    
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
                Text("Sell \(assetName)")
                    .font(.largeTitle)
                    .padding()
                
                HStack(alignment: .top) {
                    Text("Amount:")
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
                
                Button("Confirm Sell") {
                    // Handle sell action
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
