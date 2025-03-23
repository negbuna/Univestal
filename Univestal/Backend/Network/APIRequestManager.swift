import Foundation

class APIRequestManager {
    static let shared = APIRequestManager()
    
    // Rate limits
    private let stockRequestsPerSecond = 30
    private let cryptoRequestsPerDay = 10_000
    private let newsRequestsPerDay = 100
    
    // Request tracking
    private var stockRequestCount = 0
    private var cryptoRequestCount = 0
    private var newsRequestCount = 0
    private var lastStockResetTime = Date()
    private var lastCryptoResetDate = Date()
    private var lastNewsResetDate = Date()
    
    private let queue = DispatchQueue(label: "com.univestal.apirequests")
    
    private var requestQueue: [APIRequest] = []
    private var isProcessingQueue = false
    
    struct APIRequest {
        let type: RequestType
        let priority: RequestPriority
        let task: () async throws -> Void
    }
    
    enum RequestPriority: Int {
        case high = 0   // Real-time price updates
        case medium = 1 // User-initiated actions
        case low = 2    // Background updates
    }
    
    func enqueueRequest(type: RequestType, priority: RequestPriority, task: @escaping () async throws -> Void) {
        let request = APIRequest(type: type, priority: priority, task: task)
        requestQueue.append(request)
        requestQueue.sort { $0.priority.rawValue < $1.priority.rawValue }
        
        if !isProcessingQueue {
            Task { await processQueue() }
        }
    }
    
    private func processQueue() async {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true
        
        while !requestQueue.isEmpty {
            let request = requestQueue.removeFirst()
            
            switch request.type {
            case .stock:
                guard await canMakeStockRequest() else {
                    requestQueue.append(request)
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
            case .crypto:
                guard await canMakeCryptoRequest() else {
                    requestQueue.append(request)
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
            case .news:
                // Add news rate limiting if needed
                break
            }
            
            try? await request.task()
        }
        
        isProcessingQueue = false
    }
    
    func canMakeStockRequest() async -> Bool {
        if Date().timeIntervalSince(lastStockResetTime) >= 1.0 {
            stockRequestCount = 0
            lastStockResetTime = Date()
        }
        guard stockRequestCount < stockRequestsPerSecond else { return false }
        stockRequestCount += 1
        return true
    }
    
    func canMakeCryptoRequest() async -> Bool {
        if !Calendar.current.isDate(lastCryptoResetDate, inSameDayAs: Date()) {
            cryptoRequestCount = 0
            lastCryptoResetDate = Date()
        }
        guard cryptoRequestCount < cryptoRequestsPerDay else { return false }
        cryptoRequestCount += 1
        return true
    }
    
    private func updateRequestCount(type: RequestType) async {
        switch type {
        case .stock: 
            await MainActor.run { self.stockRequestCount += 1 }
        case .crypto: 
            await MainActor.run { self.cryptoRequestCount += 1 }
        case .news: 
            await MainActor.run { self.newsRequestCount += 1 }
        }
    }
    
    func trackRequest(type: RequestType) {
        Task {
            await updateRequestCount(type: type)
        }
    }
    
    enum RequestType {
        case stock, crypto, news
    }
}
