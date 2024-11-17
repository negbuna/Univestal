import SwiftUI

struct UVButtons: View {
    @ObservedObject var appData: AppData
    var uvf: UVFunctions
    
    // The "Back" and "Next" buttons
    
    var continueStack: some View {
        HStack {
            Button("Back") {
                withAnimation {
                    if appData.onboardingState > 0 && appData.onboardingState != 4 {
                        appData.onboardingState -= 1
                    } else {
                        appData.onboardingState = 0
                    }
                    print("onboardingState: \(appData.onboardingState)") // debugging
                }
            }
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(20)
            
            Button("Next") {
                withAnimation {
                    
                    if appData.onboardingState != 4 {
                        // Next goes to next step in onboarding process
                        appData.onboardingState += 1
                    } else {
                        // Next goes to Homepage
                        uvf.signUp()
                        appData.onboardingState = 3
                    }
                    
                }
            }
            .onChange(of: appData.name) {
                // Checks to make sure username crieteria is met
                if appData.onboardingState == 1 {
                    appData.isButtonDisabled = appData.name.count < 3 || appData.name.count > 16
                }
            }
            .onChange(of: appData.password) {
                // Checks to make sure password crieteria is met
                if appData.onboardingState == 2 {
                    appData.isButtonDisabled = appData.password.count < 6  || appData.password.isEmpty || appData.password != appData.confirmPassword
                }
            }
            .onChange(of: appData.confirmPassword) {
                // Checks to make sure password crieteria is met
                if appData.onboardingState == 2 {
                    appData.isButtonDisabled = appData.password.count < 6  || appData.password.isEmpty || appData.password != appData.confirmPassword
                }
            }
            .onChange(of: appData.onboardingState) {
                // Reset button state based on the onboarding state
                if appData.onboardingState == 1 {
                    // In the username section, enable/disable based on the username
                    appData.isButtonDisabled = appData.name.count < 3 || appData.name.count > 16
                } else if appData.onboardingState == 2 {
                    // In the password section, disable by default until password criteria is met
                    if appData.password.count < 6  || appData.password.isEmpty || appData.password != appData.confirmPassword {
                        appData.isButtonDisabled = true
                    } else {
                        appData.isButtonDisabled = false
                    }
                }
            }
            .disabled(appData.isButtonDisabled)
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(appData.isButtonDisabled ? Color.gray : Color.blue) // Gray out if disabled
            .cornerRadius(20)
            .opacity(appData.isButtonDisabled ? 0.5 : 1.0) // Change opacity if disabled
        }
        .padding()
    }

    // The "Log in" and "Sign up" buttons
    
    var primaryStack: some View {
        HStack {
            Button("Log in") {
                withAnimation {
                    appData.onboardingState = 4
                    appData.showLoginButton = false
                }
            }
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(20)

            Button("Sign up") {
                withAnimation {
                    appData.onboardingState = 1
                    appData.showLoginButton = false
                }
            }
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(20)
        }
        .padding()
    }

    var body: some View {
        VStack {
            if appData.onboardingState == 0 {
                // Primary stack when onboardingState is 0 (before sign-up or log-in)
                primaryStack
            } else {
                // Continue stack for the rest of the onboarding
                continueStack
            }
        }
        .padding()
    }
}
