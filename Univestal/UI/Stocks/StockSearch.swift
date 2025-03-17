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
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    @State private var isLoading = true

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
                    List(filteredStocks, id: \.symbol) { stock in
                        NavigationLink(destination: StockDetailView(stock: stock)) {
                            StockRowView(stock: stock)
                        }
                    }
                }
            }
            .task {
                if environment.stocks.isEmpty {
                    isLoading = true
                    try? await environment.fetchStockData()
                }
                isLoading = false
            }
            .navigationTitle("Stocks")
            .navigationBarBackButtonHidden(true)
            .searchable(text: $searchText)
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
//            .alert("Error", isPresented: $showError) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(errorMessage)
//            }
        }
    }
}

struct StockRowView: View {
    @EnvironmentObject var appData: AppData
    let stock: Stock
    
    private var stockName: String {
        stock.lookup?.description ?? "Stock data cannot be retrieved at this time."
    }
    
    private var formattedPrice: String {
        String(format: "$%.2f", stock.quote.currentPrice)
    }
    
    private var formattedChange: String? {
        guard let dp = stock.quote.percentChange else { return nil }
        return String(format: "$%.2f", dp)
    }
    
    private var formattedPercentChange: (text: String, color: Color)? {
        guard let dp = stock.quote.percentChange else { return nil }
        let sign = dp >= 0 ? "+" : ""
        return ("\(sign)\(String(format: "%.2f", dp))%", dp >= 0 ? .green : .red)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    // Fix: Change to use toggleStockWatchlist instead of toggleWatchlist
                    appData.toggleStockWatchlist(for: stock.symbol)
                    print("Stock watchlist after toggle: \(appData.stockWatchlist)") // Debug print
                }
            }) {
                Image(systemName: appData.stockWatchlist.contains(stock.symbol) ? "star.fill" : "star")
                    .foregroundColor(appData.stockWatchlist.contains(stock.symbol) ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle()) // Prevents the button from intercepting other taps
            
            VStack(alignment: .leading) {
                Text(stock.symbol)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(stockName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formattedPrice)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let percentChange = formattedPercentChange {
                    Text(percentChange.text)
                        .font(.subheadline)
                        .foregroundColor(percentChange.color)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
    
#Preview {
    StockSearch(searchText: .constant(""))
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(Finnhub())
}
