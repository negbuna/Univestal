//
//  Pages.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/11/24.
//

import SwiftUI

struct PageViews: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @State var showPrimary: Bool = false
    @State var showContinue: Bool = false
    
    private var welcomeSec: some View {
        GeometryReader { geometry in
            ZStack {
                ColorManager.bkgColor
                    .ignoresSafeArea()

                Text("Univestal")
                    .foregroundStyle(.primary)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                    .offset(y: showPrimary ? 0 : geometry.size.height / 2)
                    .opacity(showPrimary ? 1 : 0)
                    .frame(width: geometry.size.width, alignment: .center)
                
            }
            .onAppear {
                showContinue = false
                withAnimation(.easeOut(duration: 2)) {
                    showPrimary = true
                }
            }
        }
    }

    private var addNameSec: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text("Create a username:")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                TextField("Username (max 16 characters)", text: $appData.name)
                    .font(.headline)
                    .onChange(of: appData.name) {
                        // Allows only letters, numbers, and underscores
                        let filtered = appData.name.filter { $0.isLetter || $0.isNumber || $0 == "_" }
                        // Update the name only if filtered text is different
                        if filtered != appData.name {
                            appData.name = filtered
                        }
                        // Limit the name length to 16 characters
                        if appData.name.count > 16 {
                            appData.name = String(appData.name.prefix(16))
                        }
                        
                        appData.isButtonDisabled = !appData.validateUsername() || appData.name.count < 3 || appData.name.count > 16
                    }
                
                if appData.name.count < 3 && !appData.name.isEmpty {
                    Text("Username must be at least 3 characters.")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if appData.name.count <= 3 && appData.isUsernameTaken(appData.name) {
                    Text("Username is unavailable.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
            }
            .padding()
            .onAppear {
                showPrimary = false
                withAnimation(.easeOut(duration: 2)) {
                    showContinue = true
                }
            }
            .globeOverlay()
        }
    }

    private var addPasswordSec: some View {
        VStack(alignment: .leading) {
            Text("Create a password:")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            SecureField("Password (min 6 characters)", text: $appData.password)
                .font(.headline)
            SecureField("Confirm Password", text: $appData.confirmPassword)
                .font(.headline)
            if appData.password.count < 6 && !appData.password.isEmpty {
                Text("Password must be at least 6 characters.")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if appData.password != appData.confirmPassword {
                Text("Passwords do not match.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .globeOverlay()
    }

    private var loginSec: some View {
        VStack(alignment: .leading) {
            Text("Log in")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            TextField("Username", text: $appData.name)
                .font(.headline)
            SecureField("Password", text: $appData.password)
                .font(.headline)
            if appData.hasAttemptedLogin {
                if !appData.name.isEmpty && !appData.isUsernameTaken(appData.name) || (!appData.password.isEmpty && !appData.isPasswordCorrect(username: appData.name, password: appData.password)) {
                    Text("Incorrect username and/or password.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .globeOverlay()
    }
    
    // Page switches based on onboardingState
    var body: some View {
        VStack {
            switch appData.onboardingState {
            case 0:
                welcomeSec
            case 1:
                addNameSec
            case 2:
                addPasswordSec
            case 3:
                // Confirmation screen
                HomepageView()
            case 4:
                loginSec
            default:
                welcomeSec
            }
            
            Spacer()
            
            if appData.onboardingState > 0 && appData.onboardingState <= 2 || appData.onboardingState == 4 {
                continueStack
            } else if appData.onboardingState == 0 {
                primaryStack
            }
        }
        .background(ColorManager.bkgColor)
    }
}

#Preview {
    PageViews()
        .environmentObject(AppData())
        .environmentObject(TradingEnvironment.shared)
}

extension PageViews {
    var continueStack: some View {
        HStack {
            backButton
            nextButton
        }
        .padding()
        .onChange(of: appData.onboardingState) {
            appData.updateButtonState()
        }
        .onChange(of: appData.name) {
            appData.updateButtonState()
            if appData.onboardingState == 4 {
                appData.hasAttemptedLogin = false
            }
        }
        .onChange(of: appData.password) {
            appData.updateButtonState()
            if appData.onboardingState == 4 {
                appData.hasAttemptedLogin = false
            }
        }
        .onChange(of: appData.confirmPassword) {
            appData.updateButtonState()
        }
    }

    // Separate view for Back Button
    var backButton: some View {
        Button("Back") {
            withAnimation {
                if appData.onboardingState > 0 && appData.onboardingState != 4 {
                    appData.onboardingState -= 1
                } else {
                    appData.onboardingState = 0
                }
            }
            appData.updateButtonState()
        }
        .foregroundStyle(.white)
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(20)
    }

    // Separate view for Next Button
    var nextButton: some View {
        Button("Next") {
            withAnimation {
                if appData.onboardingState != 4 && appData.onboardingState != 2 {
                    appData.onboardingState += 1
                } else if appData.onboardingState == 2 {
                    print("Before sign-up: \(appData.password)")
                    appData.signUp()
                    print("After sign-up: \(appData.hashPassword(appData.password))")
                    appData.onboardingState = 3
                } else if appData.onboardingState == 4 {
                    appData.hasAttemptedLogin = true
                    if appData.login() {
                        appData.onboardingState = 3
                    }
                }
            }
            appData.updateButtonState()
        }
        .disabled(appData.isNextButtonDisabled)
        .foregroundStyle(.white)
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(appData.isNextButtonDisabled ? Color.gray : Color.blue)
        .cornerRadius(20)
        .opacity(appData.isNextButtonDisabled ? 0.5 : 1.0)
    }

    // The "Log in" and "Sign up" buttons
    var primaryStack: some View {
        HStack {
            Button("Log in") {
                withAnimation {
                    appData.onboardingState = 4
                    appData.showLoginButton = false
                }
                appData.updateButtonState()
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
                appData.updateButtonState()
            }
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(20)
        }
        .padding()
    }
}
