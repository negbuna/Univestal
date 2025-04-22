//
//  CryptoSearch.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import SwiftUI

struct CryptoSearch: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    @State private var selectedCoinID: String? = nil
    @State private var isLoading = true
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var searchTask: Task<Void, Never>?
    @State private var coins: [Coin] = []

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && coins.isEmpty {
                    ProgressView()
                } else {
                    List {
                        ForEach(coins) { coin in
                            NavigationLink(destination: CoinDetailView(coin: coin)) {
                                CoinRow(for: coin)
                            }
                            .onAppear {
                                if coins.last?.id == coin.id {
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
                        if coins.isEmpty && !searchText.isEmpty {
                            ContentUnavailableView(
                                "No Results",
                                systemImage: "magnifyingglass",
                                description: Text("Try searching for a coin name or symbol")
                            )
                        }
                    }
                }
            }
            .navigationTitle("Coins")
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
            .searchable(text: $searchText)
            .onChange(of: searchText) {
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
                    guard !Task.isCancelled else { return }
                    await resetAndSearch()
                }
            }
        }
    }
    
    private func resetAndSearch() async {
        currentPage = 1
        coins = []
        hasMorePages = true
        loadNextPageIfNeeded()
    }
    
    private func loadNextPageIfNeeded() {
        guard !isLoading, hasMorePages else { return }
        
        Task {
            isLoading = true
            do {
                let response = try await withRetry(maxAttempts: 3) {
                    try await environment.searchCoins(  // Use environment's method directly
                        query: searchText.isEmpty ? "" : searchText,
                        page: currentPage
                    )
                }
                coins.append(contentsOf: response.items)
                currentPage += 1
                hasMorePages = response.hasNextPage
            } catch APIError.rateLimitExceeded {
                print("Rate limit reached, using cached data")
            } catch {
                print("Search error: \(error)")
            }
            isLoading = false
        }
    }
    
    private func withRetry<T>(maxAttempts: Int = 3, task: () async throws -> T) async throws -> T {
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                return try await task()
            } catch {
                attempts += 1
                lastError = error
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * Double(attempts)))
                }
            }
        }
        throw lastError ?? APIError.requestFailed(URLError(.unknown))
    }
}

#Preview {
    CryptoSearch(searchText: .constant(""))
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
}

extension CryptoSearch {
    private func CoinRow(for coin: Coin) -> some View {
        HStack {
            Button(action: {
                appData.toggleWatchlist(for: coin.id)
            }) {
                Image(systemName: appData.watchlist.contains(coin.id) ? "star.fill" : "star")
                    .foregroundColor(appData.watchlist.contains(coin.id) ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle()) // So button taps are not intercepted
            
            VStack(alignment: .leading) {
                Text(coin.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(coin.symbol.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", coin.current_price))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(coin.price_change_percentage_24h ?? 0 >= 0 ? "+" : "")\(String(format: "%.2f", coin.price_change_percentage_24h ?? 0.00))%")
                    .font(.subheadline)
                    .foregroundColor(appData.percentColor(coin.price_change_percentage_24h ?? 0))
            }
        }
    }
}
