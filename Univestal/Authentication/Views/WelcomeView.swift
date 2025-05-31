import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @State private var showTitle = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ColorManager.bkgColor
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Univestal")
                        .foregroundStyle(.primary)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .offset(y: showTitle ? 0 : geometry.size.height / 2)
                        .opacity(showTitle ? 1 : 0)
                    
                    if showTitle {
                        HStack(spacing: 20) {
                            AuthButton(title: "Log In") {
                                viewModel.currentFlow = .login
                            }
                            
                            AuthButton(title: "Sign Up") {
                                viewModel.currentFlow = .signup
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 2)) {
                    showTitle = true
                }
            }
        }
    }
}

struct AuthButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundStyle(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(20)
        }
    }
}