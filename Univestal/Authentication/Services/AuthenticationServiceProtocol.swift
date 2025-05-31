import Foundation

protocol AuthenticationServiceProtocol {
    func signIn(username: String, password: String) async throws -> User
    func signUp(username: String, password: String) async throws -> User
    func signOut() async throws
    func resetPassword(username: String, currentPassword: String, newPassword: String) async throws
    func migrateUser(username: String, legacyCredentials: String) async throws
}