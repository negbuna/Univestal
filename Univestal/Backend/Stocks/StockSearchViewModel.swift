import Foundation
import Combine

@MainActor
class StockSearchViewModel: ObservableObject {
    @Published var stocks: [StockLookup] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var error: Error?
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private var searchTask: Task<Void, Never>?
    private let finnhub: Finnhub
    
    init(finnhub: Finnhub = .shared) {
        self.finnhub = finnhub
    }
    
    func search() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            
            // Reset state for new search
            currentPage = 1
            stocks = []
            hasMorePages = true
            await loadNextPage()
        }
    }
    
    func loadNextPageIfNeeded(currentItem: StockLookup?) {
        guard let item = currentItem else {
            Task { await loadNextPage() }
            return
        }
        
        let thresholdIndex = stocks.index(stocks.endIndex, offsetBy: -5)
        if let itemIndex = stocks.firstIndex(where: { $0.symbol == item.symbol }),
           itemIndex >= thresholdIndex {
            Task { await loadNextPage() }
        }
    }
    
    private func loadNextPage() async {
        guard !isLoading, hasMorePages, !searchQuery.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await finnhub.searchStocks(query: searchQuery, page: currentPage)
            stocks.append(contentsOf: response.items)
            currentPage += 1
            hasMorePages = response.hasNextPage
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
