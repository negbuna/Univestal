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
    @EnvironmentObject var finnhub: Finnhub
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    let storage = Storage()
    
    var filteredStocks: [Stock] {
        if searchText.isEmpty {
            return environment.stocks
        } else {
            return environment.stocks.filter { stock in
                stock.symbol.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if filteredStocks.isEmpty {
                    VStack {
                        Spacer()
                        Text("No results")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding()
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredStocks, id: \.symbol) { stock in
                            NavigationLink(destination: StockDetailView(stock: stock)) {
                                StockRowView(stock: stock)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stocks")
            .navigationBarBackButtonHidden(true)
            .searchable(text: $searchText)
//            .task {
//                // Fetch default stocks on first appearance.
//                // This should load default list (20 most common stocks).
//                if finnhub.allStocks.isEmpty {
//                    await finnhub.fetchDefaultStocks()
//                }
//                isLoading = false
//            }
//            .onAppear {
//                Task {
//                    do {
//                        // Fetch one stock for testing
//                        let symbols = ["AAPL"]
//                        let fetchedStocks = try await finnhub.fetchStocks(symbols: symbols)
//                        
//                        await MainActor.run {
//                            environment.stocks = fetchedStocks
//                            isLoading = false
//                        }
//                    } catch {
//                        print("Failed to fetch stock data:", error)
//                        errorMessage = error.localizedDescription
//                        showError = true
//                        isLoading = false
//                    }
//                }
//            }
            .onAppear {
                #if DEBUG
                environment.stocks = Stock.mockStocks
                isLoading = false
                #else
                Task {
                    do {
                        let symbols = storage.commonStocks // Start with just one for testing
                        let stocks = try await finnhub.fetchStocks(symbols: symbols)
                        await MainActor.run {
                            environment.stocks = stocks
                            isLoading = false
                        }
                    } catch {
                        print("Error:", error)
                    }
                }
                isLoading = false
                #endif
            }
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
//            .task {
//                isLoading = true
//                do {
//                    try await environment.fetchStockData()
//                } catch PaperTradingError.apiLimitExceeded {
//                    errorMessage = PaperTradingError.apiLimitExceeded.localizedDescription
//                    showError = true
//                } catch {
//                    errorMessage = error.localizedDescription
//                    showError = true
//                }
//                isLoading = false
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
        return (String(format: "%.2f%%", dp), dp >= 0 ? .green : .red)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    appData.toggleWatchlist(for: stock.symbol)
                }
            }) {
                Image(systemName: appData.watchlist.contains(stock.symbol) ? "star.fill" : "star")
                    .foregroundColor(appData.watchlist.contains(stock.symbol) ? .yellow : .gray)
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
