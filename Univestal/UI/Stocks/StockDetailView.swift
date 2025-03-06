//
//  StockDetailView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/26/25.
//

import SwiftUI

struct StockDetailView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @EnvironmentObject var finnhub: Finnhub
    @Environment(\.dismiss) private var dismiss
    let stock: Stock
    
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: 16) {
                    StockInfoView(stock: stock)
                    
                    Spacer()
                    
                    detailedTradeButtons
                    .padding()
                }
                .padding()
            }
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
            .background(RoundedRectangle(cornerRadius: 20).opacity(0.07))
            .globeOverlay()
        }
    }
}

extension StockDetailView {
    private var detailedTradeButtons: some View {
        HStack {
            NavigationLink(destination: BuyUI(asset: stock)) {
                Text("Buy")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            
            NavigationLink(destination: SellUI(asset: stock)) {
                Text("Sell")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(15)
            }
        }
    }
}

