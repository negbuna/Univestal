import Foundation
import SwiftUI

@MainActor
class SessionManager: ObservableObject {
    @Published var currentUser: User?
    
    func saveSession(user: User) {
        currentUser = user
    }
    
    func clearSession() {
        currentUser = nil
    }
}
