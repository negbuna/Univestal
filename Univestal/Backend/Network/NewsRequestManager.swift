import Foundation

actor NewsRequestManager {
    static let shared = NewsRequestManager()
    
    private let cooldownInterval: TimeInterval = 3600 // 1 hour
    private let dailyRequestLimit = 100
    private var dailyRequestCount = 0
    private var lastRequestTime: Date?
    private var lastResetDate = Date()
    
    func canMakeRequest() async -> Bool {
        resetDailyCountIfNeeded()
        
        if let lastTime = lastRequestTime {
            let timeSinceLastSearch = Date().timeIntervalSince(lastTime)
            return timeSinceLastSearch >= cooldownInterval && dailyRequestCount < dailyRequestLimit
        }
        
        return dailyRequestCount < dailyRequestLimit
    }
    
    func trackRequest() {
        lastRequestTime = Date()
        dailyRequestCount += 1
    }
    
    func timeUntilNextSearch() -> TimeInterval? {
        guard let lastTime = lastRequestTime else { return nil }
        let timeSinceLastSearch = Date().timeIntervalSince(lastTime)
        return max(0, cooldownInterval - timeSinceLastSearch)
    }
    
    private func resetDailyCountIfNeeded() {
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: Date()) {
            dailyRequestCount = 0
            lastResetDate = Date()
        }
    }
}
