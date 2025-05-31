import Foundation
import os.log

class AuthLogger {
    private static let logger = Logger(subsystem: "com.univestal.auth", category: "Authentication")
    
    static func logSignIn(username: String, success: Bool) {
        logger.log("Sign in attempt: username: \(username), success: \(success)")
    }
    
    static func logSignUp(username: String, success: Bool) {
        logger.log("Sign up attempt: username: \(username), success: \(success)")
    }
    
    static func logError(_ error: Error) {
        logger.error("Authentication error: \(error.localizedDescription)")
    }
}