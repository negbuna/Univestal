import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var sessionManager: SessionManager
    
    init() {
        // Create temporary instances for initialization
        let tempStorage = SecureStorage()
        let tempSessionManager = SessionManager(storage: tempStorage)
        let tempAuthService = AuthenticationService(
            storage: tempStorage,
            sessionManager: tempSessionManager
        )
        
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(
            authService: tempAuthService,
            sessionManager: tempSessionManager
        ))
    }
    
    var body: some View {
        VStack {
            switch viewModel.currentFlow {
            case .welcome:
                WelcomeView()
                    .environmentObject(viewModel)
            case .signup:
                SignUpView()
                    .environmentObject(viewModel)
            case .login:
                LoginView()
                    .environmentObject(viewModel)
            case .complete:
                HomepageView()
            }
        }
        .onAppear {
            viewModel.updateDependencies(
                authService: authService,
                sessionManager: sessionManager
            )
        }
    }
}
