import Foundation
import Combine

@MainActor
class CryptoListViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    @Published var isLoading = false
    @Published var hasMorePages = true
    @Published var searchQuery = ""
    
    private var currentPage = 1
    private var debounceTask: Task<Void, Never>?
    private let crypto: Crypto
    
    init(crypto: Crypto) {
        self.crypto = crypto
    }
    
    func loadNextPageIfNeeded(currentItem item: Coin? = nil) {
        guard let item = item else {
            Task { await loadNextPage() }
            return
        }
        
        let thresholdIndex = coins.index(coins.endIndex, offsetBy: -5)
        if let itemIndex = coins.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex {
            Task { await loadNextPage() }
        }
    }
    
    private func loadNextPage() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        
        do {
            let response = try await crypto.fetchMarketData(page: currentPage)
            coins.append(contentsOf: response.items)
            currentPage += 1
            hasMorePages = response.hasNextPage
        } catch {
            print("Error loading coins: \(error)")
        }
        
        isLoading = false
    }
    
    func search() {
        // Cancel any existing search
        debounceTask?.cancel()
        
        // Create new debounced search
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            if !Task.isCancelled {
                await performSearch()
            }
        }
    }
    
    private func performSearch() async {
        guard !searchQuery.isEmpty else {
            currentPage = 1
            coins = []
            hasMorePages = true
            await loadNextPage()
            return
        }
        
        isLoading = true
        do {
            let response = try await crypto.searchCoins(query: searchQuery)
            coins = response.items
            hasMorePages = response.hasNextPage
            currentPage = 2
        } catch {
            print("Search error: \(error)")
        }
        isLoading = false
    }
}
