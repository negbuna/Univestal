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
        let finnhub = Finnhub.shared
        let crypto = Crypto()
        
        // Clear expired caches
        await StockCache.shared.clearExpiredCache()
        await CryptoCache.shared.clearCache()
        
        // Queue requests with priorities
        APIRequestManager.shared.enqueueRequest(
            type: .stock,
            priority: .high
        ) {
            let stocks = try await finnhub.fetchStocks(symbols: Storage().commonStocks)
            await MainActor.run {
                self.stocks = stocks
            }
        }
        
        APIRequestManager.shared.enqueueRequest(
            type: .crypto,
            priority: .medium
        ) {
            await crypto.fetchCoins()
            await MainActor.run {
                self.coins = crypto.coins
            }
        }
        
        await MainActor.run {
            self.lastUpdateTime = Date()
        }
    }
    
    func lookupStock(query: String) async throws -> StockLookup? {
        return try await Finnhub().lookupStock(query: query)
    }
    
    deinit {
        timer?.invalidate()
    }
}
