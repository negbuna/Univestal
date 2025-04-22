import Foundation

enum CachePolicy {
    case short     // 30 seconds
    case medium    // 5 minutes
    case long      // 30 minutes
    case custom(TimeInterval)
    
    var duration: TimeInterval {
        switch self {
        case .short:  return 30
        case .medium: return 300
        case .long:   return 1800
        case .custom(let interval): return interval
        }
    }
}

enum CacheEntry<T> {
    case fresh(T)
    case stale(T)
}

actor CacheStore<Key: Codable & Hashable, Value: Codable> {
    private struct CachedItem: Codable {
        let value: Value
        let timestamp: Date
        let policy: TimeInterval
        var lastAccessed: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > policy
        }
        
        var isStale: Bool {
            let now = Date()
            return now.timeIntervalSince(timestamp) > (policy / 2)
        }
    }
    
    private var storage: [Key: CachedItem] = [:]
    private let persistentStore: String
    private var refreshTasks: [Key: Task<Void, Never>] = [:]
    
    init(name: String) {
        self.persistentStore = "com.univestal.cache.\(name)"
        Task {
            await loadFromDisk()
        }
    }
    
    func cache(_ value: Value, for key: Key, policy: CachePolicy) async throws {
        let item = CachedItem(
            value: value,
            timestamp: Date(),
            policy: policy.duration,
            lastAccessed: Date()
        )
        storage[key] = item
        try await saveToDisk()
    }
    
    func value(for key: Key, backgroundRefresh: @escaping (Key) async throws -> Value) -> CacheEntry<Value>? {
        guard let item = storage[key] else { return nil }
        
        // Update last accessed time
        storage[key]?.lastAccessed = Date()
        
        // If stale, trigger background refresh
        if item.isStale && refreshTasks[key] == nil {
            refreshTasks[key] = Task {
                do {
                    let newValue = try await backgroundRefresh(key)
                    try await self.cache(newValue, for: key, policy: .custom(item.policy))
                } catch {
                    print("Background refresh failed for \(key): \(error)")
                }
                refreshTasks[key] = nil
            }
        }
        
        // Return immediately with staleness info
        return item.isExpired ? nil : (item.isStale ? .stale(item.value) : .fresh(item.value))
    }
    
    func cancelRefresh(for key: Key) {
        refreshTasks[key]?.cancel()
        refreshTasks[key] = nil
    }
    
    func clearExpired() async {
        storage = storage.filter { !$0.value.isExpired }
        try? await saveToDisk()
    }
    
    private func saveToDisk() async throws {
        let data = try JSONEncoder().encode(storage)
        UserDefaults.standard.set(data, forKey: persistentStore)
    }
    
    private func loadFromDisk() async {
        guard let data = UserDefaults.standard.data(forKey: persistentStore) else { return }
        do {
            storage = try JSONDecoder().decode([Key: CachedItem].self, from: data)
            await clearExpired() // Clean up on load
        } catch {
            print("❌ Failed to load cache from disk: \(error)")
            storage = [:] // Reset storage on decode error
        }
    }
    
    deinit {
        refreshTasks.values.forEach { $0.cancel() }
    }
}

extension CacheStore {
    func cachePaginated<T>(_ response: PaginatedResponse<T>, for key: Key, policy: CachePolicy) async throws where Value == PaginatedResponse<T> {
        // Cache the page
        try await cache(response, for: key, policy: policy)
        
        // Update pagination metadata
        let metaKey = "\(key)_meta" as! Key
        let meta = PaginationMeta(lastPage: response.page, totalPages: response.totalPages)
        try await cache(meta as! Value, for: metaKey, policy: policy)
    }
    
    private struct PaginationMeta: Codable {
        let lastPage: Int
        let totalPages: Int
        let timestamp: Date
        
        init(lastPage: Int, totalPages: Int) {
            self.lastPage = lastPage
            self.totalPages = totalPages
            self.timestamp = Date()
        }
    }
}
