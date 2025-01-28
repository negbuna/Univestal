//
//  StockSearch.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/26/25.
//

import SwiftUI

struct StockSearch: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    var filteredStocks: [Stock] {
        if searchText.isEmpty {
            return environment.stocks
        } else {
            return environment.stocks.filter { $0.symbol.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    List(filteredStocks) { stock in
                        HStack {
                            Button(action: {
                                appData.toggleStockWatchlist(for: stock.symbol)
                            }) {
                                Image(systemName: appData.stockWatchlist.contains(stock.symbol) ? "star.fill" : "star")
                                    .foregroundColor(appData.stockWatchlist.contains(stock.symbol) ? .yellow : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            NavigationLink(destination: StockDetailView(stock: stock)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(stock.symbol)
                                            .font(.headline)
                                        Text(stock.name)
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "$%.2f", stock.price))
                                            .font(.headline)
                                        Text(String(format: "%.2f%%", stock.percentChange))
                                            .font(.subheadline)
                                            .foregroundColor(stock.percentChange >= 0 ? .green : .red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Stocks")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                isLoading = true
                do {
                    try await environment.fetchStockData()
                } catch PaperTradingError.apiLimitExceeded {
                    errorMessage = PaperTradingError.apiLimitExceeded.localizedDescription
                    showError = true
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    StockSearch()
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
}
