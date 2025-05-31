import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            Text("Welcome Back")
                .font(.title)
                .fontWeight(.bold)
            
            // Input Fields
            VStack(spacing: 15) {
                CustomTextField(
                    text: $username,
                    placeholder: "Username",
                    icon: "person"
                )
                
                CustomTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock",
                    isSecure: true
                )
            }
            
            // Login Button
            AuthButton(title: "Log In") {
                Task {
                    await viewModel.handleLogin(
                        username: username,
                        password: password
                    )
                }
            }
            .disabled(username.isEmpty || password.isEmpty)
            .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            
            // Sign Up Link
            Button {
                viewModel.currentFlow = .signup
            } label: {
                Text("Don't have an account? ")
                    .foregroundStyle(.secondary) +
                Text("Sign Up")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .alert("Login Error", 
               isPresented: $viewModel.showError,
               actions: {
                   Button("OK", role: .cancel) { }
               },
               message: {
                   Text(viewModel.errorMessage)
               })
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}