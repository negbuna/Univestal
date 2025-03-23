import Foundation

actor StockCache {
    static let shared = StockCache()
    private let defaults = UserDefaults.standard
    
    private let stockMetadataKey = "cached_stock_metadata"
    private let lastFetchTimeKey = "last_fetch_time"
    private let quoteCacheDuration: TimeInterval = 300 // 5 minutes
    private let metadataCacheDuration: TimeInterval = 86400 // 24 hours
    
    struct CachedStockMetadata: Codable {
        let symbol: String
        let lookup: StockLookup?
        let metrics: StockMetrics?
        let timestamp: Date
    }
    
    func cacheMetadata(symbol: String, lookup: StockLookup?, metrics: StockMetrics?) {
        let metadata = CachedStockMetadata(
            symbol: symbol,
            lookup: lookup,
            metrics: metrics,
            timestamp: Date()
        )
        
        var cached = getCachedMetadata()
        cached[symbol] = metadata
        
        if let encoded = try? JSONEncoder().encode(cached) {
            defaults.set(encoded, forKey: stockMetadataKey)
        }
    }
    
    func getCachedMetadata() -> [String: CachedStockMetadata] {
        guard let data = defaults.data(forKey: stockMetadataKey),
              let cached = try? JSONDecoder().decode([String: CachedStockMetadata].self, from: data)
        else {
            return [:]
        }
        return cached
    }
    
    func clearExpiredCache() {
        var cached = getCachedMetadata()        
        cached = cached.filter { !isMetadataExpired($0.value.timestamp) }
        
        if let encoded = try? JSONEncoder().encode(cached) {
            defaults.set(encoded, forKey: stockMetadataKey)
        }
    }
    
    private func isMetadataExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > metadataCacheDuration
    }
}
