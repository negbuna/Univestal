actor RateLimiter {
    private var tokens: Int
    private let limit: Int
    private let refillInterval: TimeInterval
    private var lastRefill: Date
    
    init(limit: Int, refillInterval: TimeInterval) {
        self.limit = limit
        self.tokens = limit
        self.refillInterval = refillInterval
        self.lastRefill = Date()
    }
    
    func acquire() async -> Bool {
        refillTokens()
        guard tokens > 0 else { return false }
        tokens -= 1
        return true
    }
    
    private func refillTokens() {
        let now = Date()
        let timePassed = now.timeIntervalSince(lastRefill)
        let tokensToAdd = Int(timePassed / refillInterval) * limit
        tokens = min(tokens + tokensToAdd, limit)
        lastRefill = now
    }
}
