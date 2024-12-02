//
//  NetworkManagerView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/11/24.
//

import SwiftUI

struct AlpacaView: View {
    @ObservedObject var alpacaModel: AlpacaModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    // Display Stocks
                    if !alpacaModel.stocks.isEmpty {
                        Text("Stocks")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(alpacaModel.stocks, id: \.self) { stock in
                            VStack(alignment: .leading) {
                                Text("Symbol: \(stock.symbol)")
                                Text("Price: \(stock.price)")
                            }
                            .padding()
                        }
                    } else {
                        Text("No stocks available.")
                            .padding()
                    }
                    
                    // Display Account Info
                    if let account = alpacaModel.account {
                        Text("Account Info")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(alignment: .leading) {
                            Text("Account ID: \(account.id)")
                            Text("Cash: \(account.cash)")
                            Text("Portfolio Value: \(account.portfolioValue)")
                        }
                        .padding()
                    } else {
                        Text("No account information available.")
                            .padding()
                    }
                    
                    // Display Orders
                    if !alpacaModel.orders.isEmpty {
                        Text("Orders")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(alpacaModel.orders, id: \.id) { order in
                            VStack(alignment: .leading) {
                                Text("Order ID: \(order.id)")
                                Text("Symbol: \(order.symbol)")
                                Text("Quantity: \(order.qty)")
                                Text("Filled Quantity: \(order.filledQty)")
                                Text("Status: \(order.status)")
                            }
                            .padding()
                        }
                    } else {
                        Text("No orders available.")
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Alpaca")
            .onAppear {
                // Fetch data when view appears
                alpacaModel.fetchStocks()
                alpacaModel.fetchAccount()
                alpacaModel.fetchOrders()
            }
        }
    }
}

#Preview {
    AlpacaView(alpacaModel: AlpacaModel())
}
