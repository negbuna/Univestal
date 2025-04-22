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
            stockRows
            loadingIndicator
        }
        .overlay(emptyStateOverlay)
    }
    
    private var stockRows: some View {
        ForEach(stocks, id: \.symbol) { lookup in
            StockRowItem(lookup: lookup, onAppear: {
                checkLoadMore(for: lookup)
            })
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
    
    private var emptyStateOverlay: some View {
        Group {
            if stocks.isEmpty && !searchText.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try searching for a company name or symbol")
                )
            }
        }
    }
    
    private func checkLoadMore(for stock: StockLookup) {
        if stocks.last?.symbol == stock.symbol {
            loadNextPageIfNeeded()
        }
    }
    
    private func resetAndSearch() async {
        currentPage = 1
        stocks = []
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

// Break out row item into separate view
struct StockRowItem: View {
    let lookup: StockLookup
    let onAppear: () -> Void
    
    var body: some View {
        NavigationLink {
            StockRowDestination(lookup: lookup)
        } label: {
            StockRowView(lookup: lookup)
        }
        .onAppear(perform: onAppear)
    }
}

// Handle async loading of full stock data
struct StockRowDestination: View {
    let lookup: StockLookup
    @State private var stock: Stock?
    @EnvironmentObject var finnhub: Finnhub
    
    var body: some View {
        Group {
            if let stock = stock {
                StockDetailView(stock: stock)
            } else {
                ProgressView()
            }
        }
        .task {
            // Load full stock data
            stock = try? await loadFullStock(from: lookup)
        }
    }
    
    private func loadFullStock(from lookup: StockLookup) async throws -> Stock {
        async let quote = finnhub.fetchStockQuote(symbol: lookup.symbol)
        async let metrics = finnhub.fetchStockMetrics(symbol: lookup.symbol)
        
        return try await Stock(
            symbol: lookup.symbol,
            quote: quote,
            metrics: metrics,
            lookup: lookup
        )
    }
}

// Update row view to accept StockLookup
struct StockRowView: View {
    let lookup: StockLookup
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        HStack {
            watchlistButton
            stockInfo
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var watchlistButton: some View {
        Button {
            withAnimation {
                appData.toggleStockWatchlist(for: lookup.symbol)
            }
        } label: {
            Image(systemName: appData.stockWatchlist.contains(lookup.symbol) ? "star.fill" : "star")
                .foregroundColor(appData.stockWatchlist.contains(lookup.symbol) ? .yellow : .gray)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private var stockInfo: some View {
        VStack(alignment: .leading) {
            Text(lookup.symbol)
                .font(.headline)
            Text(lookup.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
    
#Preview {
    StockSearch(searchText: .constant(""))
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(Finnhub())
}
