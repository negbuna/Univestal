//
//  Functions.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/11/24.
//

import SwiftUI
import CryptoKit

class UVFunctions: ObservableObject {
    
    @AppStorage("username") var currentUsername: String?
    @AppStorage("signed_in") var currentUserSignedIn: Bool = false
    @AppStorage("hashed_password") var storedHashedPassword: String?
    @AppStorage("usernames") var storedUsernamesData: Data = Data()
    @AppStorage("joindate") var storedJoinDateString: String = ""
    
    var univestalUsers: Set<String> = []
    
    @ObservedObject var appData: AppData
    
    init(appData: AppData) {
        self.appData = appData
        univestalUsers = Set(decodeUsernames()) // Initializes the set with the usernames from AppStorage
        refreshUserSet() // Initialize the set with the stored data
    }
    
    // Encode usernames to Data
    func encodeUsernames(_ usernames: [String]) -> Data {
        try! JSONEncoder().encode(usernames)
    }
    
    // Decode usernames from Data
    func decodeUsernames() -> [String] {
        guard let usernames = try? JSONDecoder().decode([String].self, from: storedUsernamesData) else {
            return []
        }
        return usernames
    }
    
    // Refreshes the set to make sure it is synchronized
    func refreshUserSet() {
        // Reload the usernames from @AppStorage into the set
        univestalUsers = Set(decodeUsernames())
    }
    
    // Check if username is taken
    func isUsernameTaken(_ username: String) -> Bool {
        // Checks if the username is in the set
        return univestalUsers.contains(username)
    }
    
    // Add user to the list of usernames
    func addUser() {
        var usernames = decodeUsernames()
        
        // Add the username to both the list and the set
        usernames.append(appData.name)
        univestalUsers.insert(appData.name)
        
        // Save back to @AppStorage
        storedUsernamesData = encodeUsernames(usernames)
        
        // Store other user details
        currentUsername = appData.name
        storedHashedPassword = hashPassword(appData.password)
        currentUserSignedIn = true
        
        // Update the join date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        storedJoinDateString = dateFormatter.string(from: Date.now)
        
        // Refresh the set after update
        refreshUserSet()
    }
    
    // Removes user if account is deleted
    func removeUser(_ username: String) {
        // Remove from the set
        univestalUsers.remove(username)
        
        // Remove from the stored list and update AppStorage
        var usernames = decodeUsernames()
        usernames.removeAll { $0 == username }
        storedUsernamesData = encodeUsernames(usernames)
    }
    
    // Validate username
    func validateUsername() -> Bool {
        // Makes sure username is at least 3 characters and not already taken
        if appData.name.count >= 3 && !isUsernameTaken(appData.name) {
            return true
        } else {
            appData.invalidText = "Username is unavailable."
            return false
        }
    }
    
    // Sanitize username to only allow letters, numbers, and underscores
    func sanitizeUsername(_ username: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")) // Allows A-Z, a-z, 0-9, and _
        return String(username.unicodeScalars.filter { allowedCharacters.contains($0) })
    }
    
    // Hash password
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Validate password
    func validatePassword() -> Bool {
        if appData.password.count >= 6 && appData.password == appData.confirmPassword {
            return true
        } else {
            return false
        }
    }
    
    // Registers a user and adds their info to the set of users
    func signUp() {
        currentUsername = appData.name
        currentUserSignedIn = true
        addUser()
    }
    
    // Check if password is correct
    func isPasswordCorrect(name: String, password: String) -> Bool {
        let usernames = decodeUsernames()
        if usernames.contains(name), let storedPassword = storedHashedPassword, storedPassword == hashPassword(password) {
            return true
        }
        return false
    }
    
    // Login
    func login() {
        // Refresh the user set to ensure it has the latest data
        refreshUserSet()
        
        // Verify the username exists, and that the password is correct
        if isUsernameTaken(appData.name) && isPasswordCorrect(name: appData.name, password: appData.password) {
            currentUsername = appData.name // Assigns name to user in AppStorage
            currentUserSignedIn = true // Confirms the user is signed in, granting access to the homepage
            appData.onboardingState = 3
        }
    }
}
