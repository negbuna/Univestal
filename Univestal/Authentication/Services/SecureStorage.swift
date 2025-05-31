import Foundation
import Security

protocol SecureStorageProtocol {
    func saveCredentials(_ credentials: Credentials) throws
    func getCredentials(for username: String) throws -> Credentials
    func isUsernameTaken(_ username: String) throws -> Bool
    func deleteUser(_ username: String) throws
}

struct SecureStorage: SecureStorageProtocol {
    private let service = "com.univestal.auth"
    
    func saveCredentials(_ credentials: Credentials) throws {
        let data = try JSONEncoder().encode(credentials)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentials.username,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: credentials.username
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(
                updateQuery as CFDictionary,
                attributes as CFDictionary
            )
            
            guard updateStatus == errSecSuccess else {
                throw AuthError.storageError
            }
        } else if status != errSecSuccess {
            throw AuthError.storageError
        }
    }
    
    func getCredentials(for username: String) throws -> Credentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(Credentials.self, from: data)
        else {
            throw AuthError.userNotFound
        }
        
        return credentials
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