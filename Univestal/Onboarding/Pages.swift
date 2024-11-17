//
//  Pages.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/11/24.
//

import SwiftUI

struct PageViews: View {
    @ObservedObject var appData = AppData()
    
    @State var showPrimary: Bool = false
    @State var showContinue: Bool = false
    
    var uvf: UVFunctions {
        UVFunctions(appData: appData)
    }
    
    var obb: UVButtons {
        UVButtons(appData: appData, uvf: uvf)
    }
    
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
                        
                        appData.isButtonDisabled = !uvf.validateUsername() || appData.name.count < 3 || appData.name.count > 16
                    }
                
                if appData.name.count < 3 && !appData.name.isEmpty {
                    Text("Username must be at least 3 characters.")
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
            .overlay(alignment: .topLeading) {
                Image(systemName: "globe")
                    .foregroundStyle(.primary)
                    .opacity(0.07)
                    .font(.system(size: 800))
                    .offset(x: 20, y: 2)
                    .ignoresSafeArea()
            }
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
        .overlay(alignment: .topLeading) {
            Image(systemName: "globe")
                .foregroundStyle(.primary)
                .opacity(0.07)
                .font(.system(size: 800))
                .offset(x: 20, y: 2)
                .ignoresSafeArea()
        }
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
            if !appData.name.isEmpty && !uvf.isUsernameTaken(appData.name) {
                Text("Username does not exist.")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if !appData.password.isEmpty && !uvf.isPasswordCorrect(name: appData.name, password: appData.password) {
                Text("Incorrect username or password.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .overlay(alignment: .topLeading) {
            Image(systemName: "globe")
                .foregroundStyle(.primary)
                .opacity(0.07)
                .font(.system(size: 800))
                .offset(x: 20, y: 2)
                .ignoresSafeArea()
        }
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
                HomepageView(appData: appData)
            case 4:
                loginSec
            default:
                welcomeSec
            }
            
            Spacer()
            
            if appData.onboardingState > 0 && appData.onboardingState <= 2 || appData.onboardingState == 4 {
                obb.continueStack
            } else if appData.onboardingState == 0 {
                obb.primaryStack
            }
            
        }
        .background(ColorManager.bkgColor)
    }
}

#Preview {
    PageViews(appData: AppData())
}
