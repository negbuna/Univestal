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
    @Published private(set) var isLoading = false
    private let cache = NSCache<NSString, CacheEntry>()te(set) var lastError: String?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    rivate init() {
    private final class CacheEntry {    setupTimer()
        let data: Any
        let timestamp: Date
        etupTimer() {
        init(data: Any) {TimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self.data = dataask {
            self.timestamp = Date()       await self?.refreshData()
        }       }
            }
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < 300 // 5 minutes
        }
    }
    
    private func cached<T>(_ key: String) -> T? {
        guard let entry = cache.object(forKey: key as NSString) as? CacheEntry,
              entry.isValid else {
            cache.removeObject(forKey: key as NSString)
            return nillet news = News()
        }
        return entry.data as? T
    }async let stocksTask = finnhub.fetchStocks(symbols: Storage().commonStocks)
     () = crypto.fetchCoins()
    private init() {
        setupTimer()
    }(fetchedStocks, _) = try await (stocksTask, cryptoTask)
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task {elf.coins = crypto.coins
                await self?.refreshData()
            }iggering alert
        }   news.fetchArticles(query: "") { articles in
    }   self.articles = articles
    
    func refreshData() async {       
        do {           self.lastUpdateTime = Date()
            let finnhub = Finnhub.shared        }
            let crypto = Crypto()
            let news = News()
                   print("Error refreshing data: \(error)")
            // Execute all fetches concurrently    }
            async let stocksTask = finnhub.fetchStocks(symbols: Storage().commonStocks)
            async let cryptoTask: () = crypto.fetchCoins()
            
            // Wait for both to complete   
            let (fetchedStocks, _) = try await (stocksTask, cryptoTask)    func lookupStock(query: String) async throws -> StockLookup? {


























}    }        timer?.invalidate()    deinit {        }        return try await Finnhub().lookupStock(query: query)    func lookupStock(query: String) async throws -> StockLookup? {        }        }            print("Error refreshing data: \(error)")        } catch {            }                self.lastUpdateTime = Date()                                }                    self.articles = articles                news.fetchArticles(query: "") { articles in                // Fetch articles without triggering alert                                self.coins = crypto.coins                self.stocks = fetchedStocks            await MainActor.run {                    return try await Finnhub().lookupStock(query: query)
    }
    
    deinit {
        timer?.invalidate()
    }
}
