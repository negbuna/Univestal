import Foundation
import Combine

@MainActor
class AppData: ObservableObject {
    static let shared = AppData()
    
    let userId: String
    let deviceId: String
    
    @Published var currentUsername: String = ""
    @Published var storedJoinDateString: String?
    @Published var watchlist: Set<String> = []
    @Published var stockWatchlist: Set<String> = []
    
    private let defaults = UserDefaults.standard
    
    private init() {
        // Initialize userId first
        if let stored = UserDefaults.standard.string(forKey: "userId") {
            self.userId = stored
        } else {
            self.userId = UUID().uuidString
            UserDefaults.standard.set(self.userId, forKey: "userId")
        }
        
        if let stored = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = stored
        } else {
            self.deviceId = UUID().uuidString
            UserDefaults.standard.set(self.deviceId, forKey: "deviceId")
        }
        
        loadStoredData()
    }
    
    private func loadStoredData() {
        if let storedUsername = defaults.string(forKey: "currentUsername") {
            currentUsername = storedUsername
        }
        
        if let storedJoinDate = defaults.string(forKey: "storedJoinDateString") {
            storedJoinDateString = storedJoinDate
        }
        
        if let storedWatchlist = defaults.array(forKey: "watchlist") as? [String] {
            watchlist = Set(storedWatchlist)
        }
        
        if let storedStockWatchlist = defaults.array(forKey: "stockWatchlist") as? [String] {
            stockWatchlist = Set(storedStockWatchlist)
        }
    }
    
    func saveUsername(_ username: String) {
        currentUsername = username
        defaults.set(username, forKey: "currentUsername")
    }
    
    func saveJoinDate(_ dateString: String) {
        storedJoinDateString = dateString
        defaults.set(dateString, forKey: "storedJoinDateString")
    }
    
    func toggleWatchlist(for coinId: String) {
        if watchlist.contains(coinId) {
            watchlist.remove(coinId)
        } else {
            watchlist.insert(coinId)
        }
        defaults.set(Array(watchlist), forKey: "watchlist")
    }
    
    func toggleStockWatchlist(for symbol: String) {
        if stockWatchlist.contains(symbol) {
            stockWatchlist.remove(symbol)
        } else {
            stockWatchlist.insert(symbol)
        }
        defaults.set(Array(stockWatchlist), forKey: "stockWatchlist")
    }
    
    func formattedCurrentYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
}