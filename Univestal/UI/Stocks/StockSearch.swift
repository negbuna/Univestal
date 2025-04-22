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
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && environment.stocks.isEmpty {
                    ProgressView()
                } else {
                    stockListView
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
            .onChange(of: searchText) {
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
    
    private var stockListView: some View {
        List {
            ForEach(environment.stocks, id: \.symbol) { stock in
                StockRowItem(stock: stock)
            }
            loadingIndicator
        }
        .overlay {
            if environment.stocks.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try searching for a company name or symbol")
                )
            }
        }
    }
    
    private var loadingIndicator: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    private func resetAndSearch() async {
        currentPage = 1
        hasMorePages = true
        loadNextPageIfNeeded()
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
                currentPage += 1
                hasMorePages = response.hasNextPage
            } catch {
                print("Search error: \(error)")
            }
            isLoading = false
        }
    }
}

// Update StockRowItem to use Stock directly instead of StockLookup
struct StockRowItem: View {
    let stock: Stock
    
    var body: some View {
        NavigationLink {
            StockDetailView(stock: stock)
        } label: {
            StockRowView(stock: stock)
        }
    }
}

// Update row view to accept Stock directly
struct StockRowView: View {
    let stock: Stock
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        HStack {
            watchlistButton
            
            VStack(alignment: .leading) {
                Text(stock.symbol)
                    .font(.headline)
                Text(stock.lookup?.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Add price information to match coin display
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", stock.quote.currentPrice))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let percentChange = stock.quote.percentChange {
                    Text("\(percentChange >= 0 ? "+" : "")\(String(format: "%.2f", percentChange))%")
                        .font(.subheadline)
                        .foregroundColor(appData.percentColor(percentChange))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var watchlistButton: some View {
        Button {
            withAnimation {
                appData.toggleStockWatchlist(for: stock.symbol)
            }
        } label: {
            Image(systemName: appData.stockWatchlist.contains(stock.symbol) ? "star.fill" : "star")
                .foregroundColor(appData.stockWatchlist.contains(stock.symbol) ? .yellow : .gray)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
    
#Preview {
    StockSearch(searchText: .constant(""))
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(Finnhub())
}
