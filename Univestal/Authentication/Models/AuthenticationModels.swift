import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
}

struct Credentials: Codable {
    let username: String
    let password: String
}

enum AuthState {
    case authenticated
    case unauthenticated
}

enum AuthError: LocalizedError {
    case invalidInput
    case usernameTaken
    case userNotFound
    case invalidPassword
    case storageError
    case biometricsNotAvailable
    case biometricsFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidInput: return "Please check your input"
        case .usernameTaken: return "Username is already taken"
        case .userNotFound: return "User not found"
        case .invalidPassword: return "Invalid password"
        case .storageError: return "Storage error occurred"
        case .biometricsNotAvailable: return "Biometric authentication not available"
        case .biometricsFailed: return "Biometric authentication failed"
        }
    }
}