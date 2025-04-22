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
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var searchTask: Task<Void, Never>?
    @State private var stocks: [StockLookup] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && stocks.isEmpty {
                    ProgressView()
                } else {
                    List {
                        ForEach(stocks, id: \.symbol) { stock in
                            NavigationLink(destination: StockDetailView(stock: stock)) {
                                StockRowView(stock: stock)
                            }
                            .onAppear {
                                if stocks.last?.symbol == stock.symbol {
                                    loadNextPageIfNeeded()
                                }
                            }
                        }
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .overlay {
                        if stocks.isEmpty && !searchText.isEmpty {
                            ContentUnavailableView(
                                "No Results",
                                systemImage: "magnifyingglass",
                                description: Text("Try searching for a company name or symbol")
                            )
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
            .onChange(of: searchText) { _ in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
                    guard !Task.isCancelled else { return }
                    await resetAndSearch()
                }
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
        }
    }
    
    private func resetAndSearch() async {
        currentPage = 1
        stocks = []
        hasMorePages = true
        await loadNextPageIfNeeded()
    }
    
    private func loadNextPageIfNeeded() {
        guard !isLoading, hasMorePages else { return }
        
        Task {
            isLoading = true
            do {
                let response = try await finnhub.searchStocks(
                    query: searchText.isEmpty ? "" : searchText,
                    page: currentPage
                )
                stocks.append(contentsOf: response.items)
                currentPage += 1
                hasMorePages = response.hasNextPage
            } catch {
                print("Search error: \(error)")
            }
            isLoading = false
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
                    appData.toggleStockWatchlist(for: stock.symbol)
                    print("Stock watchlist after toggle: \(appData.stockWatchlist)")
                }
            }) {
                Image(systemName: appData.stockWatchlist.contains(stock.symbol) ? "star.fill" : "star")
                    .foregroundColor(appData.stockWatchlist.contains(stock.symbol) ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            
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
