import Foundation

actor CryptoCache {
    static let shared = CryptoCache()
    private let defaults = UserDefaults.standard
    
    private let cryptoDataKey = "cached_crypto_data"
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    struct CachedCryptoData: Codable {
        let coins: [Coin]
        let timestamp: Date
    }
    
    func cacheCoins(_ coins: [Coin]) {
        let cache = CachedCryptoData(coins: coins, timestamp: Date())
        if let encoded = try? JSONEncoder().encode(cache) {
            defaults.set(encoded, forKey: cryptoDataKey)
        }
    }
    
    func getCachedCoins() -> [Coin]? {
        guard let data = defaults.data(forKey: cryptoDataKey),
              let cache = try? JSONDecoder().decode(CachedCryptoData.self, from: data),
              !isCacheExpired(cache.timestamp) else {
            return nil
        }
        return cache.coins
    }
    
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheDuration
    }
    
    func clearCache() {
        defaults.removeObject(forKey: cryptoDataKey)
    }
}
