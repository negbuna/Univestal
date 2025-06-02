import Foundation
import CryptoKit
import LocalAuthentication
import Combine
import CoreData

@MainActor
class AuthenticationService: ObservableObject, AuthenticationServiceProtocol {
    private let storage: SecureStorageProtocol
    let sessionManager: SessionManager 
    
    init(storage: SecureStorageProtocol = SecureStorage(), sessionManager: SessionManager) {
        self.storage = storage
        self.sessionManager = sessionManager
    }
    
    func signIn(username: String, password: String) async throws -> User {
        guard !username.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }
        
        let hashedPassword = hashPassword(password)
        let credentials = try storage.getCredentials(for: username)
        
        guard credentials.password == hashedPassword else {
            throw AuthError.invalidPassword
        }
        
        let user = User(id: UUID().uuidString, username: username)
        return user
    }
    
    func signUp(username: String, password: String) async throws -> User {
        // First validate input
        guard !username.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }
        
        // Check if username is taken
        let isTaken = try storage.isUsernameTaken(username)
        guard !isTaken else {
            throw AuthError.usernameTaken
        }
        
        let hashedPassword = hashPassword(password)
        try storage.saveCredentials(
            Credentials(username: username, password: hashedPassword)
        )
        
        let user = User(id: UUID().uuidString, username: username)
        return user
    }
    
    func signOut() async throws {
        sessionManager.clearSession()
    }
    
    func resetPassword(username: String, currentPassword: String, newPassword: String) async throws {
        // Verify current password
        let currentHashedPassword = hashPassword(currentPassword)
        let credentials = try storage.getCredentials(for: username)
        
        guard credentials.password == currentHashedPassword else {
            throw AuthError.invalidPassword
        }
        
        // Save new password
        let newHashedPassword = hashPassword(newPassword)
        try storage.saveCredentials(
            Credentials(username: username, password: newHashedPassword)
        )
    }
    
    func migrateUser(username: String, legacyCredentials: String) async throws {
        guard let data = Data(base64Encoded: legacyCredentials),
              let credentials = try? JSONDecoder().decode(Credentials.self, from: data) else {
            throw AuthError.invalidInput
        }
        
        try storage.saveCredentials(credentials)
    }
    
    func deleteAccount(username: String) async throws {
        guard let currentUser = sessionManager.currentUser else {
            throw AuthError.userNotFound
        }
        
        // Ensure we're deleting the correct account
        guard currentUser.username == username else {
            throw AuthError.invalidInput
        }
        
        let context = PersistenceController.shared.container.viewContext
        
        // Delete watchlist items without using username predicate
        let watchlistRequest = NSFetchRequest<WatchlistItem>(entityName: "WatchlistItem")
        let stockWatchlistRequest = NSFetchRequest<StockWatchlistItem>(entityName: "StockWatchlistItem")
        
        // Fetch and delete all items
        if let watchlistItems = try? context.fetch(watchlistRequest) {
            for item in watchlistItems {
                context.delete(item)
            }
        }
        
        if let stockWatchlistItems = try? context.fetch(stockWatchlistRequest) {
            for item in stockWatchlistItems {
                context.delete(item)
            }
        }
        
        try context.save()
        
        // Delete from secure storage
        try storage.deleteUser(username)
        
        // Clear session on main thread
        await MainActor.run {
            sessionManager.clearSession()
        }
    }
    
    private func deleteUserData(for username: String) async throws {
        // Delete from Core Data
        let context = PersistenceController.shared.container.viewContext
        
        // Delete watchlist items
        let watchlistRequest = NSFetchRequest<WatchlistItem>(entityName: "WatchlistItem")
        watchlistRequest.predicate = NSPredicate(format: "username == %@", username)
        let watchlistItems = try context.fetch(watchlistRequest)
        
        // Delete stock watchlist items
        let stockWatchlistRequest = NSFetchRequest<StockWatchlistItem>(entityName: "StockWatchlistItem")
        stockWatchlistRequest.predicate = NSPredicate(format: "username == %@", username)
        let stockWatchlistItems = try context.fetch(stockWatchlistRequest)
        
        // Perform deletions
        for item in watchlistItems {
            context.delete(item)
        }
        for item in stockWatchlistItems {
            context.delete(item)
        }
        
        try context.save()
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
