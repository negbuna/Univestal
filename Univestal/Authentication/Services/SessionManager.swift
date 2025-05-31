import Foundation
import SwiftUI

class SessionManager: ObservableObject {
    @Published private(set) var currentUser: User?
    private let storage: SecureStorageProtocol
    
    init(storage: SecureStorageProtocol = SecureStorage()) {
        self.storage = storage
        loadSavedSession()
    }
    
    func saveSession(user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
            currentUser = user
        }
    }
    
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        currentUser = nil
    }
    
    private func loadSavedSession() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }
}