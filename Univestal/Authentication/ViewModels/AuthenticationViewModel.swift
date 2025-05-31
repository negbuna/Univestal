import SwiftUI
import Combine

enum AuthFlow {
    case welcome
    case signup
    case login
    case complete
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published private(set) var authState: AuthState = .unauthenticated
    @Published var currentFlow: AuthFlow = .welcome
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var authService: AuthenticationService
    private var sessionManager: SessionManager
    
    init(authService: AuthenticationService, sessionManager: SessionManager) {
        self.authService = authService
        self.sessionManager = sessionManager
    }
    
    func navigateTo(_ flow: AuthFlow) {
        currentFlow = flow
    }
    
    func handleLogin(username: String, password: String) async {
        do {
            let user = try await authService.signIn(username: username, password: password)
            sessionManager.saveSession(user: user)
            authState = .authenticated
            currentFlow = .complete
        } catch {
            handleError(error)
        }
    }
    
    func handleSignUp(username: String, password: String) async {
        do {
            let user = try await authService.signUp(username: username, password: password)
            sessionManager.saveSession(user: user)
            authState = .authenticated
            currentFlow = .complete
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = (error as? AuthError)?.errorDescription ?? "An unknown error occurred"
        showError = true
    }
    
    func updateDependencies(authService: AuthenticationService, sessionManager: SessionManager) {
        self.authService = authService
        self.sessionManager = sessionManager
    }
}