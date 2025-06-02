import Foundation
import Security

protocol SecureStorageProtocol {
    func saveCredentials(_ credentials: Credentials) throws
    func getCredentials(for username: String) throws -> Credentials
    func isUsernameTaken(_ username: String) throws -> Bool
    func deleteUser(_ username: String) throws
}

class SecureStorage: SecureStorageProtocol {
    private let service = "com.univestal.auth"
    private let defaults = UserDefaults.standard
    
    func saveCredentials(_ credentials: Credentials) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentials.username,
            kSecValueData as String: credentials.password.data(using: .utf8) ?? Data()
        ]
        
        // First try to delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Then add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.storageError
        }
    }
    
    func getCredentials(for username: String) throws -> Credentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8)
        else {
            throw AuthError.userNotFound
        }
        
        return Credentials(username: username, password: password)
    }
    
    func isUsernameTaken(_ username: String) throws -> Bool {
        do {
            _ = try getCredentials(for: username)
            return true
        } catch AuthError.userNotFound {
            return false
        } catch {
            throw error
        }
    }
    
    func deleteUser(_ username: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.storageError
        }
    }
}