import Foundation

class AuthMigrationService {
    private let authService: AuthenticationService
    private let userDefaults = UserDefaults.standard
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func migrateExistingUsers() async throws {
        guard !userDefaults.bool(forKey: "hasPerformedMigration") else {
            return
        }
        
        if let username = userDefaults.string(forKey: "username"),
           let storedUserCredentialsData = userDefaults.string(forKey: "storedUserCredentials") {
            try await authService.migrateUser(
                username: username,
                legacyCredentials: storedUserCredentialsData
            )
        }
        
        userDefaults.set(true, forKey: "hasPerformedMigration")
    }
}