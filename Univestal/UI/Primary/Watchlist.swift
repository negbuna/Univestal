//
//  Watchlist.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import SwiftUI

struct Watchlist: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @EnvironmentObject var finnhub: Finnhub
    @State private var searchText = ""
    @State private var selectedCoinID: String? = nil
    @State private var isLoading = true

    // Add computed property to filter coins
    private var watchlistCoins: [Coin] {
        // Get coins that are in the watchlist
        let coins = environment.coins.filter { coin in
            appData.watchlist.contains(coin.id)
        }
        print("📋 Found \(coins.count) coins in watchlist")
        print("🔍 Watchlist IDs: \(appData.watchlist)")
        print("🎯 Matched coins: \(coins.map { $0.id })")
        return coins
    }

    private var watchlistStocks: [Stock] {
        let stocks = environment.stocks.filter { stock in
            appData.stockWatchlist.contains(stock.symbol)
        }
        print("📈 Found \(stocks.count) stocks in watchlist")
        print("🔍 Stock Watchlist symbols: \(appData.stockWatchlist)")
        print("🎯 Matched stocks: \(stocks.map { $0.symbol })")
        return stocks
    }

    var filteredWatchlistCoins: [Coin] {
        if searchText.isEmpty {
            return watchlistCoins
        } else {
            return watchlistCoins.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var selectedCoin: Coin? {
        guard let id = selectedCoinID else { return nil }
        return environment.findCoin(byId: id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        WatchlistSection(
                            title: "Cryptocurrencies",
                            isEmpty: watchlistCoins.isEmpty
                        ) {
                            if !watchlistCoins.isEmpty {
                                ScrollView {
                                    LazyVStack(spacing: 0) {
                                        ForEach(watchlistCoins) { coin in
                                            CoinWatchlistRow(coin: coin)
                                                .id(coin.id)
                                        }
                                    }
                                }
                                .frame(maxHeight: 300) // Set maximum height for scroll area
                            }
                        }
                        
                        WatchlistSection(
                            title: "Stocks",
                            isEmpty: watchlistStocks.isEmpty
                        ) {
                            if !watchlistStocks.isEmpty {
                                ScrollView {
                                    LazyVStack(spacing: 0) {
                                        ForEach(watchlistStocks, id: \.symbol) { stock in
                                            StockWatchlistRow(stock: stock)
                                                .id(stock.symbol)
                                        }
                                    }
                                }
                                .frame(maxHeight: 300) // Set maximum height for scroll area
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .task {
                print("🔄 Loading coins...")
                print("📱 Current watchlist: \(appData.watchlist)")
                if environment.coins.isEmpty {
                    await environment.fetchCryptoData()
                }
                print("✅ Loaded \(environment.coins.count) coins")
                isLoading = false
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: Search()) {
                        Image(systemName: "plus")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

// Helper Views
struct WatchlistSection<Content: View>: View {
    let title: String
    let isEmpty: Bool
    let content: () -> Content
    
    init(
        title: String,
        isEmpty: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isEmpty = isEmpty
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
            
            if isEmpty {
                Text("No assets yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CoinWatchlistRow: View {
    @EnvironmentObject var appData: AppData
    let coin: Coin
    
    var body: some View {
        HStack {
            Button(action: {
                appData.toggleWatchlist(for: coin.id)
            }) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            NavigationLink(destination: CoinDetailView(coin: coin)) {
                VStack(alignment: .leading) {
                    Text(coin.name)
                        .font(.headline)
                    Text(coin.symbol.uppercased())
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(coin.current_price, format: .currency(code: "USD"))
                        .font(.headline)
                    
                    if let percentChange = coin.price_change_percentage_24h {
                        Text("\(percentChange >= 0 ? "+" : "")\(percentChange, specifier: "%.2f")%")
                            .foregroundColor(percentChange >= 0 ? .green : .red)
                    }
                        
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.2))
                .offset(y: 16),
            alignment: .bottom
        )
        .onAppear {
            print("🎯 Rendering coin: \(coin.id)")
        }
    }
}

struct StockWatchlistRow: View {
    @EnvironmentObject var appData: AppData
    let stock: Stock
    
    var body: some View {
        HStack {
            Button(action: {
                print("Before toggle: \(appData.stockWatchlist)") // Debug print
                appData.toggleStockWatchlist(for: stock.symbol)
                print("After toggle: \(appData.stockWatchlist)") // Debug print
            }) {
                Image(systemName: appData.stockWatchlist.contains(stock.symbol) ? "star.fill" : "star")
                    .foregroundColor(appData.stockWatchlist.contains(stock.symbol) ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            NavigationLink(destination: StockDetailView(stock: stock)) {
                VStack(alignment: .leading) {
                    Text(stock.symbol)
                        .font(.headline)
                    Text(stock.lookup?.description ?? "")
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "$%.2f", stock.quote.currentPrice))
                        .font(.headline)
                    if let change = stock.quote.percentChange {
                        Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")%")
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.2))
                .offset(y: 16),
            alignment: .bottom
        )
    }
}

#Preview {
    Watchlist()
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(Finnhub())
}
