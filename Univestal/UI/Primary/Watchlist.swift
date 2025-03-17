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

    var filteredWatchlistCoins: [Coin] {
        let watchlistCoins = environment.coins.filter { appData.watchlist.contains($0.id) }
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
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            WatchlistSection(
                                title: "Cryptocurrencies",
                                isEmpty: appData.watchlist.isEmpty
                            ) {
                                if !filteredWatchlistCoins.isEmpty {
                                    ForEach(filteredWatchlistCoins) { coin in
                                        CoinWatchlistRow(coin: coin)
                                    }
                                }
                            }
                            
                            WatchlistSection(
                                title: "Stocks",
                                isEmpty: appData.stockWatchlist.isEmpty
                            ) {
                                let watchlistStocks = environment.stocks.filter { appData.stockWatchlist.contains($0.symbol) }
                                if !watchlistStocks.isEmpty {
                                    ForEach(watchlistStocks, id: \.symbol) { stock in
                                        StockWatchlistRow(stock: stock)
                                    }
                                }
                            }
                        }
                        .padding()
                        // Add debug prints to track watchlist state
                        .onAppear {
                            print("Current stock watchlist: \(appData.stockWatchlist)")
                            print("Available stocks: \(environment.stocks.map { $0.symbol })")
                        }
                    }
                    .searchable(text: $searchText)
                }
            }
            .task {
                if environment.coins.isEmpty {
                    await environment.fetchCryptoData()
                }
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
                Text("No items in watchlist")
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
                    Text(String(format: "$%.2f", coin.current_price))
                        .font(.headline)
                    Text(String(format: "%.2f%%", coin.price_change_percentage_24h ?? 0.00))
                        .font(.subheadline)
                        .foregroundColor(appData.percentColor(coin.price_change_percentage_24h ?? 0))
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
                        Text(String(format: "%.2f%%", change))
                            .font(.subheadline)
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
