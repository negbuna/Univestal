import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)
            
            // Input Fields
            VStack(spacing: 15) {
                CustomTextField(
                    text: $username,
                    placeholder: "Choose a username",
                    icon: "person"
                )
                
                CustomTextField(
                    text: $password,
                    placeholder: "Create password",
                    icon: "lock",
                    isSecure: true
                )
                
                CustomTextField(
                    text: $confirmPassword,
                    placeholder: "Confirm password",
                    icon: "lock.rotation",
                    isSecure: true
                )
            }
            
            // Requirements Text
            VStack(alignment: .leading, spacing: 4) {
                RequirementRow(
                    icon: username.count >= 3 ? "checkmark.circle.fill" : "xmark.circle.fill",
                    text: "Username must be at least 3 characters",
                    isMet: username.count >= 3
                )
                
                RequirementRow(
                    icon: password.count >= 6 ? "checkmark.circle.fill" : "xmark.circle.fill",
                    text: "Password must be at least 6 characters",
                    isMet: password.count >= 6
                )
                
                RequirementRow(
                    icon: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill",
                    text: "Passwords must match",
                    isMet: password == confirmPassword
                )
            }
            .padding(.vertical)
            
            // Sign Up Button
            AuthButton(title: "Create Account") {
                Task {
                    await viewModel.handleSignUp(
                        username: username,
                        password: password
                    )
                }
            }
            .disabled(!isValidInput)
            .opacity(isValidInput ? 1.0 : 0.6)
            
            // Login Link
            Button {
                viewModel.currentFlow = .login
            } label: {
                Text("Already have an account? ")
                    .foregroundStyle(.secondary) +
                Text("Log In")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .alert("Sign Up Error", 
               isPresented: $viewModel.showError,
               actions: {
                   Button("OK", role: .cancel) { }
               },
               message: {
                   Text(viewModel.errorMessage)
               })
    }
    
    private var isValidInput: Bool {
        !username.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isMet ? .green : .red)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}