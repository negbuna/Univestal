import Foundation
import CoreData
import Combine

@MainActor
class StockTierManager: ObservableObject {
    static let shared = StockTierManager()
    
    struct TierConfig {
        let updateInterval: TimeInterval
        let maxStocks: Int
        let priority: Int  // Lower number = higher priority
    }
    
    let tiers: [StockTier: TierConfig] = [
        .primary: TierConfig(updateInterval: 10, maxStocks: 50, priority: 1),    // Update every 10s
        .secondary: TierConfig(updateInterval: 30, maxStocks: 150, priority: 2),  // Update every 30s
        .extended: TierConfig(updateInterval: 120, maxStocks: 500, priority: 3)   // Update every 2m
    ]
    
    // Cached data
    @Published private(set) var stocksByTier: [StockTier: [Stock]] = [:]
    private var updateTimers: [StockTier: Timer] = [:]
    private var lastUpdateTime: [StockTier: Date] = [:]
    private let cache = NSCache<NSString, CachedStock>()
    
    // Rate limiting
    private let requestQueue = DispatchQueue(label: "com.univestal.stockfetch", qos: .userInitiated)
    private let tokenQueue = DispatchQueue(label: "com.univestal.tokens")
    private actor TokenManager {
        private(set) var tokens: Int
        private var lastReplenishment: Date
        private let maxTokens: Int
        
        init(initialTokens: Int) {
            self.tokens = initialTokens
            self.maxTokens = initialTokens
            self.lastReplenishment = Date()
        }
        
        func acquireToken() -> Bool {
            if tokens > 0 {
                tokens -= 1
                return true
            }
            return false
        }
        
        func replenishTokens() {
            let now = Date()
            let timeSinceLastReplenishment = now.timeIntervalSince(lastReplenishment)
            let tokensToAdd = Int(timeSinceLastReplenishment) * maxTokens
            tokens = min(tokens + tokensToAdd, maxTokens)
            lastReplenishment = now
        }
    }
    
    private let tokenManager: TokenManager
    
    init() {
        self.tokenManager = TokenManager(initialTokens: 25)
        setupTiers()
        startTokenReplenishment()
    }
    
    private func setupTiers() {
        stocksByTier[.primary] = []
        stocksByTier[.secondary] = []
        stocksByTier[.extended] = []
        
        // Initialize each tier with its stocks
        configureTierStocks()
    }
    
    private func configureTierStocks() {
        // Primary tier -> Most traded stocks
        let primarySymbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "META", "NVDA", "TSLA", "JPM", "V", "WMT"]
        
        // Secondary tier -> Medium volume stocks
        let secondarySymbols = ["AMD", "INTC", "CRM", "NFLX", "DIS", "BA", "GS", "HD", "MCD", "PG"]
        
        // Tertiary tier -> populated on-demand
        
        Task {
            await loadTier(.primary, symbols: primarySymbols)
            await loadTier(.secondary, symbols: secondarySymbols)
        }
    }
    
    func startUpdates() {
        tiers.forEach { tier, config in
            startTierUpdates(tier, interval: config.updateInterval)
        }
    }
    
    private func startTierUpdates(_ tier: StockTier, interval: TimeInterval) {
        updateTimers[tier]?.invalidate()
        updateTimers[tier] = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.updateTier(tier)
            }
        }
    }
    
    private func startTokenReplenishment() {
        Task {
            while !Task.isCancelled {
                await tokenManager.replenishTokens()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    private func acquireToken() async -> Bool {
        await tokenManager.acquireToken()
    }
}

// MARK: - Tier Management
extension StockTierManager {
    enum StockTier: Int {
        case primary
        case secondary
        case extended
    }
    
    private func loadTier(_ tier: StockTier, symbols: [String]) async {
        var stocks: [Stock] = []
        
        for symbol in symbols {
            if let cached = getCachedStock(symbol) {
                stocks.append(cached)
                continue
            }
            
            guard await acquireToken() else {
                // Wait and try again
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            }
            
            do {
                let stock = try await Finnhub.shared.fetchStocks(symbols: [symbol]).first
                if let stock = stock {
                    stocks.append(stock)
                    cacheStock(stock)
                }
            } catch {
                print("Error loading stock \(symbol): \(error)")
            }
        }
        
        await MainActor.run {
            stocksByTier[tier] = stocks
            lastUpdateTime[tier] = Date()
        }
    }
    
    private func updateTier(_ tier: StockTier) async {
        guard let stocks = stocksByTier[tier] else { return }
        let symbols = stocks.map { $0.symbol }
        await loadTier(tier, symbols: symbols)
    }
}

// MARK: - Caching
extension StockTierManager {
    private final class CachedStock: NSObject {
        let stock: Stock
        let timestamp: Date
        
        init(stock: Stock, timestamp: Date = Date()) {
            self.stock = stock
            self.timestamp = timestamp
            super.init()
        }
    }
    
    private func cacheStock(_ stock: Stock) {
        let cached = CachedStock(stock: stock)
        cache.setObject(cached, forKey: stock.symbol as NSString)
    }
    
    private func getCachedStock(_ symbol: String) -> Stock? {
        guard let cached = cache.object(forKey: symbol as NSString) else { 
            return nil 
        }
        
        // Check if cache is still valid (5 minutes)
        if Date().timeIntervalSince(cached.timestamp) > 300 {
            cache.removeObject(forKey: symbol as NSString)
            return nil
        }
        
        return cached.stock
    }
}
