//
//  UVOnboardingViews.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/5/24.
//

import SwiftUI
import CryptoKit



// MARK: STATE VARS

func hashPassword(_ password: String) -> String {
    let inputData = Data(password.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

struct UVOnboardingViews: View {
    
    @EnvironmentObject var appData: AppData
    
    // Onboarding states
    /*
     stages of onboarding process
     0 - welcome screen
     1 - add name
     2 - add age
     */
    
    // MARK: bools for buttons and text
    @State private var isAnimating: Bool = false
    @State private var showButton: Bool = false
    
    //onboarding
    @State private var showNextButton: Bool = false
    @State private var showNextButton2: Bool = false
    @State private var showNextButton3: Bool = false
    
    
    //logging in
    @State private var showLoginButton: Bool = false
    @State private var showContinueButton: Bool = false
    @State private var invalidtext = "Invalid username: At least 3 characters"
    @State private var invalidPasswordText = "Invalid password: At least 6 characters"
    
    @State var onboardingState: Int = 0
    
    @State private var buttonOpacity = 0.0
    
    @State var selectedTab: Int = 0
    
    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading))
    
    
    //MARK: user vars
    @State var name: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State private var univestalUsers: Set<String> = []
    
    // App storage
    @AppStorage("username") var currentUsername: String?
    @AppStorage("age") var currentUserAge: Int?
    @AppStorage("signed_in") var currentUserSignedIn: Bool = false
    @AppStorage("hashed_password") var storedHashedPassword: String?
    @AppStorage("usernames") var storedUsernamesData: Data = Data()
    @AppStorage("joindate") var storedJoinDateString: String = ""
    
    // MARK: BODY
    
    var body: some View {
        VStack {
            ZStack {
                switch onboardingState {
                case 0:
                    welcomeSec
                        .transition(transition)
                case 1:
                    addNameSec
                        .transition(transition)
                case 2:
                    addPasswordSec
                        .transition(transition)
                case 4:
                    HomepageView(appData: appData)
                case 5:
                    loginSec
                default:
                    welcomeSec
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                if showButton {
                    bottomButton
                        .opacity(buttonOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2)) {
                                buttonOpacity = 1.0
                            }
                        }
                }
                
                if showNextButton {
                    nextButton
                        .opacity(buttonOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2)) {
                                buttonOpacity = 1.0
                            }
                        }
                }
                
                if showNextButton2 {
                    nextButton2
                        .opacity(buttonOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2)) {
                                buttonOpacity = 1.0
                            }
                        }
                }
                
                if showNextButton3 {
                    nextButton3
                        .opacity(buttonOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2)) {
                                buttonOpacity = 1.0
                            }
                        }
                }
                
                if showLoginButton {
                    loginButton
                        .opacity(buttonOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2)) {
                                buttonOpacity = 1.0
                            }
                        }
                }
                
                if showContinueButton {
                    continueButton
                        .opacity(buttonOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2)) {
                                buttonOpacity = 1.0
                            }
                        }
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorManager.bkgColor) // Ensure background color
    }
}

#Preview {
    UVOnboardingViews()
}

// MARK: BUTTONS

extension UVOnboardingViews {
    
    private var bottomButton: some View {
        Button("Sign up") {
            withAnimation {
                onboardingState = 1
                showButton = false
                showNextButton = false
                showLoginButton = false
            }
        }
        .foregroundStyle(.white)
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(20)
    }
    
    private var nextButton: some View {
        Button("Next") {
            withAnimation {
                onboardingState = 2
                showNextButton = false
            }
        }
        .disabled(name.count < 3 || name.count > 16)
        .foregroundStyle(.white)
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(20)
    }
    
    private var nextButton2: some View {
        Button("Next") {
            withAnimation {
                onboardingState = 3
                showNextButton2 = false
            }
        }
        .foregroundStyle(.white)
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(20)
    }
    
    private var nextButton3: some View {
        Button("Finish") {
            withAnimation {
                onboardingState = 4
                showNextButton2 = false
                addUser()
                showNextButton3 = false
                currentUserSignedIn = true
            }
        }
        .foregroundStyle(.white)
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(20)
    }
    
    private var loginButton: some View {
            Button("Log in") {
                withAnimation {
                    onboardingState = 5
                    showNextButton = false
                }
            }
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(20)
        }
    
    private var continueButton: some View {
            Button("Continue") {
                withAnimation {
                    if isPasswordCorrect(name: name, password: password) {
                        onboardingState = 4
                        currentUserSignedIn = true
                        showContinueButton = false
                    } else {
                        login()
                    }
                    
                    showNextButton = false
                    showLoginButton = false
                }
            }
            .foregroundStyle(.white)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(20)
        }
    
    
    //MARK: VARS
    
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
                    .offset(y: isAnimating ? 0 : geometry.size.height / 2)
                    .opacity(isAnimating ? 1 : 0)
                    .frame(
                        width: geometry.size.width,
                        alignment: .center)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .center)
                .onAppear {
                    withAnimation(.easeOut(duration: 2)) {
                        isAnimating = true
                        showLoginButton = true
                        showButton = true
                    }
                }
        }
    }
    
    private var addNameSec: some View {
        VStack(alignment: .leading) {
            Text("Create a username:")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            TextField("Username (max 16 characters)", text: $name)
                .font(.headline)
                .onChange(of: name) { oldValue, newValue in
                    name = String(newValue.prefix(16))
                    validateUsername()
                }
                .onAppear {
                    name = "" // Ensure initial value is empty
                    validateUsername() // Validate on appear to update showNextButton state
                }
            
            // Username registration cases
            if name.count < 3 && !name.isEmpty {
                Text(invalidtext)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if isUsernameTaken(name) {
                Text(invalidtext)
                    .font(.caption)
                    .foregroundStyle(.red)
            } 
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 2)) {
                isAnimating = true
                showLoginButton = false
                showButton = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                validateUsername() // Validate on appear to update showNextButton state
            }
        }
        .overlay(alignment: .topLeading) {
            if onboardingState == 1 {
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
                SecureField("Password (min 6 characters)", text: $password)
                    .font(.headline)
                    .onAppear {
                        password = "" // Ensure initial value is empty
                    }
                SecureField("Confirm Password", text: $confirmPassword)
                    .font(.headline)
                    .onAppear {
                        confirmPassword = "" // Ensure initial value is empty
                    }
                
                // Password validation cases
                if password.count < 6 && !password.isEmpty {
                    Text(invalidPasswordText)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if password != confirmPassword {
                    Text("Passwords do not match.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .onAppear {
                withAnimation(.easeOut(duration: 2)) {
                    isAnimating = true
                    showLoginButton = false
                    showButton = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showNextButton2 = true
                }
            }
            .overlay(alignment: .topLeading) {
                if onboardingState == 3 {
                    Image(systemName: "globe")
                        .foregroundStyle(.primary)
                        .opacity(0.07)
                        .font(.system(size: 800))
                        .offset(x: 20, y: 295)
                        .ignoresSafeArea()
                }
            }
            .onChange(of: password) { oldValue, newValue in
                validatePassword()
            }
        }
    
//    private var addAgeSec: some View {
//        VStack(alignment: .leading) {
//            Text("What's your age?")
//                .font(.largeTitle)
//                .fontWeight(.semibold)
//                .foregroundStyle(.primary)
//            Text("It's never too late to start investing.")
//                .font(.caption)
//                .foregroundStyle(.primary)
//            Slider(value: $age, in: 14...100, step: 1)
//            Text("\(String(format: "%.0f", age))")
//                .font(.largeTitle)
//                .foregroundStyle(.primary)
//                
//        }
//        .padding()
//        .onAppear {
//            withAnimation(.easeOut(duration: 2)) {
//                isAnimating = true
//                showLoginButton = false
//                showButton = false
//            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                showNextButton3 = true
//            }
//        }
//        .overlay(alignment: .topLeading) {
//            if onboardingState == 2 {
//                Image(systemName: "globe")
//                    .foregroundStyle(.primary)
//                    .opacity(0.07)
//                    .font(.system(size: 800))
//                    .offset(x: 20, y: 2)
//                    .ignoresSafeArea()
//            }
//        }
//    }
    
    //MARK: LOGIN SECTION
    
    private var loginSec: some View {
            VStack(alignment: .leading) {
                Text("Log in")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                TextField("Username", text: $name)
                    .font(.headline)
                    .onAppear {
                        name = "" // Ensure initial value is empty
                        showLoginButton = false
                        showButton = false
                        showContinueButton = false
                    }
                SecureField("Password", text: $password)
                    .font(.headline)
                    .onAppear {
                        password = "" // Ensure initial value is empty
                    }
                
                // Error messages
                if !name.isEmpty && !isUsernameTaken(name) {
                    Text("Username does not exist.")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if !password.isEmpty && !isPasswordCorrect(name: name, password: password) {
                    Text("Incorrect username or password.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .onAppear {
                withAnimation(.easeOut(duration: 2)) {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showContinueButton = true
                }
            }
            .overlay(alignment: .topLeading) {
                if onboardingState == 5 {
                    Image(systemName: "globe")
                        .foregroundStyle(.primary)
                        .opacity(0.07)
                        .font(.system(size: 800))
                        .offset(x: 20, y: 2)
                        .ignoresSafeArea()
                }
            }
        }
    
    // MARK: FUNCTIONS
    
    private func isUsernameTaken(_ username: String) -> Bool {
            let usernames = decodeUsernames()
            return usernames.contains(username)
        }
        
    // Add user to the stored list
    private func addUser() {
        var usernames = decodeUsernames()
        usernames.append(name)
        storedUsernamesData = encodeUsernames(usernames)
        currentUsername = name
        storedHashedPassword = hashPassword(password)
        currentUserSignedIn = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy" // Customize format as needed (e.g., "M/d/yy")
        storedJoinDateString = dateFormatter.string(from: Date.now)
    }
        
    // Encode usernames to Data
    private func encodeUsernames(_ usernames: [String]) -> Data {
        try! JSONEncoder().encode(usernames)
    }
    
    // Decode usernames from Data
    private func decodeUsernames() -> [String] {
        guard let usernames = try? JSONDecoder().decode([String].self, from: storedUsernamesData) else {
            return []
        }
        return usernames
    }
    
    // Validate username
    private func validateUsername() {
        if name.count >= 3 && !isUsernameTaken(name) {
            showNextButton = true
        } else if isUsernameTaken(name) == true {
            invalidtext = "Username is taken."
        } else {
            showNextButton = false
        }
        
    }
    
    private func sanitizeUsername(_ username: String) -> String {
            let allowedCharacters = CharacterSet.alphanumerics
            return String(username.unicodeScalars.filter { allowedCharacters.contains($0) })
        }
    
    private func validatePassword() {
            if password.count >= 6 && password == confirmPassword {
                showNextButton = true
            } else {
                showNextButton = false
            }
        }
    
    func signIn() {
        currentUsername = name
        currentUserSignedIn = true
        addUser()
    }
    
    //logging in
    
    private func isPasswordCorrect(name: String, password: String) -> Bool {
        let usernames = decodeUsernames()
        if usernames.contains(name), let storedPassword = storedHashedPassword, storedPassword == hashPassword(password) {
            return true
        }
        return false
    }
    
    func login() {
        if isUsernameTaken(name) && isPasswordCorrect(name: name, password: password) {
            currentUsername = name
            currentUserSignedIn = true
            onboardingState = 4
        }
    }
}

