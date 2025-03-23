import Foundation
import Combine

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published private(set) var lastUpdateTime: Date?
    private let updateInterval: TimeInterval = 3600 // 1 hour
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Data stores
    @Published private(set) var stocks: [Stock] = []
    @Published private(set) var coins: [Coin] = []
    @Published private(set) var articles: [Article] = []
    
    private init() {
        setupTimer()
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshData()
            }
        }
    }
    
    func refreshData() async {
        do {
            let finnhub = Finnhub.shared
            let crypto = Crypto()
            let news = News()
            
            // Clear expired caches
            await StockCache.shared.clearExpiredCache()
            await CryptoCache.shared.clearCache() // Clear expired crypto cache
            
            // Execute all fetches concurrently
            async let stocksTask = finnhub.fetchStocks(symbols: Storage().commonStocks)
            async let cryptoTask: () = crypto.fetchCoins()
            
            let (fetchedStocks, _) = try await (stocksTask, cryptoTask)
            
            await MainActor.run {
                self.stocks = fetchedStocks
                self.coins = crypto.coins
                
                news.fetchArticles(query: "") { articles in
                    self.articles = articles
                }
                
                self.lastUpdateTime = Date()
            }
        } catch {
            print("Error refreshing data: \(error)")
        }
    }
    
    func lookupStock(query: String) async throws -> StockLookup? {
        return try await Finnhub().lookupStock(query: query)
    }
    
    deinit {
        timer?.invalidate()
    }
}
