import Foundation

enum APIResourceType: String {
    case stockQuote
    case stockMetrics
    case stockLookup
    case cryptoPrice
    case cryptoDetails
    case newsArticle
    
    var cachePolicy: CachePolicy {
        switch self {
        case .stockQuote:    return .short    // 30 sec
        case .stockMetrics:  return .medium   // 5 min
        case .stockLookup:   return .long     // 30 min
        case .cryptoPrice:   return .medium   // 5 min
        case .cryptoDetails: return .medium   // 5 min
        case .newsArticle:   return .long     // 30 min
        }
    }
    
    var refreshInterval: TimeInterval {
        switch self {
        case .stockQuote:    return 30    // 30 sec
        case .stockMetrics:  return 300   // 5 min
        case .stockLookup:   return 1800  // 30 min
        case .cryptoPrice:   return 300   // 5 min
        case .cryptoDetails: return 300   // 5 min
        case .newsArticle:   return 1800  // 30 min
        }
    }
    
    var shouldBackgroundRefresh: Bool {
        switch self {
        case .newsArticle: return false  // Limited daily quota
        default: return true
        }
    }
}

@MainActor
class APICache {
    static let shared = APICache()
    
    private var cacheStores: [APIResourceType: Any] = [:]
    
    private func store<T: Codable>(for type: APIResourceType) -> CacheStore<String, T> {
        if let existing = cacheStores[type] as? CacheStore<String, T> {
            return existing
        }
        let new = CacheStore<String, T>(name: type.rawValue)
        cacheStores[type] = new
        return new
    }
    
    func cache<T: Codable>(_ value: T, type: APIResourceType, key: String) async {
        do {
            try await store(for: type).cache(value, for: key, policy: type.cachePolicy)
        } catch {
            print("❌ Failed to cache value: \(error)")
        }
    }
    
    func value<T: Codable>(type: APIResourceType, key: String) async -> T? {
        if let cached: CacheEntry<T> = await store(for: type).value(for: key, backgroundRefresh: { _ in
            // Default empty closure since we don't need background refresh
            throw CacheError.refreshNotAllowed
        }) {
            switch cached {
            case .fresh(let value), .stale(let value):
                return value
            }
        }
        return nil
    }
    
    func value<T: Codable>(
        type: APIResourceType,
        key: String,
        backgroundRefresh: @escaping (String) async throws -> T
    ) async -> CacheEntry<T>? {
        await store(for: type).value(for: key) { key in
            if type.shouldBackgroundRefresh {
                return try await backgroundRefresh(key)
            }
            throw CacheError.refreshNotAllowed
        }
    }
    
    func clearExpired() async {
        for (_, store) in cacheStores {
            if let typedStore = store as? CacheStore<String, Codable> {
                await typedStore.clearExpired()
            }
        }
    }
    
    enum CacheError: Error {
        case refreshNotAllowed
    }
}
