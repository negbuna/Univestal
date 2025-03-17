//
//  AppData.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/14/24.
//

import Foundation
import CryptoKit
import CoreData
import SwiftUI

class AppData: ObservableObject {
    @Published var onboardingState: Int = 0
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var showLoginButton: Bool = false
    @Published var isButtonDisabled: Bool = true
    @Published var hasAttemptedLogin: Bool = false
    @Published var watchlist: Set<String> = []
    @Published var stockWatchlist: Set<String> = []
    private let viewContext: NSManagedObjectContext

    @AppStorage("username") var currentUsername: String = "" // The active user
    @AppStorage("joindate") var storedJoinDateString: String?
    @AppStorage("signed_in") var currentUserSignedIn: Bool = false
    @AppStorage("storedUserCredentials") var storedUserCredentialsData: String = "" // JSON string for user credentials in AppStorage
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        loadWatchlistFromCoreData()
    }
    
    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading))
    
    // MARK: User Credentials

    var userCredentials: [String: String] {
        get {
            // Decode the storedUserCredentialsData (from JSON String to Dictionary)
            guard let data = storedUserCredentialsData.data(using: .utf8),
                  let decodedDict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:] // Return an empty dictionary if decoding fails
            }
            return decodedDict
        }
        set(newDict) {
            DispatchQueue.main.async {
                // Encode the new dictionary to a JSON String and store it
                if let encodedData = try? JSONEncoder().encode(newDict),
                   let jsonString = String(data: encodedData, encoding: .utf8) {
                    self.storedUserCredentialsData = jsonString
                }
            }
        }
    }

    // MARK: - User Management
    
    var isNextButtonDisabled: Bool {
        switch onboardingState {
        case 1:
            return name.count < 3 || name.count > 16 || !validateUsername()
        case 2:
            return password.count < 6 || password.isEmpty || password != confirmPassword
        default:
            return false
        }
    }

    // Function to add a username and password
    func addUser(_ username: String, password: String) {
        var updatedCredentials = userCredentials
        updatedCredentials[username] = hashPassword(password)
        userCredentials = updatedCredentials
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        storedJoinDateString = dateFormatter.string(from: Date())
    }

    // Function to remove a user
    func removeUser(_ username: String) {
        DispatchQueue.main.async {
            var updatedCredentials = self.userCredentials
            updatedCredentials.removeValue(forKey: username)
            self.userCredentials = updatedCredentials
        }
    }

    // Check if username is taken
    func isUsernameTaken(_ username: String) -> Bool {
        return userCredentials.keys.contains(username)
    }

    // Validate username
    func validateUsername() -> Bool {
        if name.count >= 3 && !isUsernameTaken(name) {
            return true
        }
        return false
    }

    // Sanitize username to only allow letters, numbers, and underscores
    func sanitizeUsername(_ username: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
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
        if password.count >= 6 && password == confirmPassword {
            return true
        } else {
            return false
        }
    }
    
    // Check if password is correct
    func isPasswordCorrect(username: String, password: String) -> Bool {
        guard let storedHashedPassword = userCredentials[username] else {
            return false
        }
        return storedHashedPassword == hashPassword(password)
    }
    
    // Sign up user and add their info
    func signUp() {
        currentUsername = name
        currentUserSignedIn = true
        addUser(name, password: password)
        print("Stored hashed password: \(hashPassword(password))")
    }
    
    // Log in user
    func login() -> Bool {
        if isUsernameTaken(name) && isPasswordCorrect(username: name, password: password) {
            currentUsername = name
            currentUserSignedIn = true
            return true
        } else {
            return false
        }
    }
    
    // Sign out user
    func signOut() {
        DispatchQueue.main.async {
            self.currentUserSignedIn = false
            self.currentUsername = ""
            self.onboardingState = 0
            print("Sign-out: currentUsername is now '\(self.currentUsername)'")
            print("User signed in is \(self.currentUserSignedIn)")
        }
    }

    // Delete user account
    func deleteAccount() {
        removeUser(currentUsername)
        currentUserSignedIn = false
        onboardingState = 0
    }
    
    func formattedCurrentYear() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy" // Year format (yyyy for full year)
        return dateFormatter.string(from: Date.now)
    }
    
    func updateButtonState() {
        if onboardingState == 1 {
            // Username section: enable/disable based on the username criteria
            isButtonDisabled = name.count < 3 || name.count > 16
        } else if onboardingState == 2 {
            // Password section: disable by default until password criteria is met
            isButtonDisabled = password.count < 6 || password.isEmpty || password != confirmPassword
            print("Checking password. Stored: \(password), Input Hashed: \(hashPassword(password))")
        }
    }
    
    // MARK: Crypto
    
    func formatLargeNumber(_ number: Double) -> String {
        let absNumber = abs(number)
        switch absNumber {
        case 1_000_000_000_000...:
            return String(format: "$%.2fT", number / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "$%.2fB", number / 1_000_000_000)
        case 1_000_000...:
            return String(format: "$%.2fM", number / 1_000_000)
        case 1_000...:
            return String(format: "$%.0f", number)
        default:
            return String(format: "$%.2f", number)
        }
    }
    
    func formatPercentChange(_ number: Double) -> String {
        let sign = number >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", number))%"
    }
    
    func percentColor(_ number: Double) -> Color {
        if number > 0 {
            return .green // Positive change
        } else if number < 0 {
            return .red // Negative change
        } else {
            return .white // No change
        }
    }
    
    func loadWatchlistFromCoreData() {
        let request = NSFetchRequest<WatchlistItem>(entityName: "WatchlistItem")
        let stockRequest = NSFetchRequest<StockWatchlistItem>(entityName: "StockWatchlistItem")
        
        do {
            let items = try viewContext.fetch(request)
            let stockItems = try viewContext.fetch(stockRequest)
            watchlist = Set(items.compactMap { $0.coinId })
            stockWatchlist = Set(stockItems.compactMap { $0.stockSymbol })  // Use correct attribute
            print("Loaded stock watchlist: \(stockWatchlist)")  // Add debug print
        } catch {
            print("Error loading watchlists: \(error)")
        }
    }

    func toggleWatchlist(for coinId: String) {
        if watchlist.contains(coinId) {
            removeFromWatchlist(coinId)
        } else {
            addToWatchlist(coinId)
        }
        objectWillChange.send() // Force UI update
    }
    
    func toggleStockWatchlist(for symbol: String) {
        if stockWatchlist.contains(symbol) {
            removeFromStockWatchlist(symbol)
        } else {
            addToStockWatchlist(symbol)
        }
        objectWillChange.send()
    }
    
    private func addToWatchlist(_ coinId: String) {
        let item = NSEntityDescription.insertNewObject(forEntityName: "WatchlistItem", 
                                                    into: viewContext) as! WatchlistItem
        item.coinId = coinId
        item.dateAdded = Date()
        
        do {
            try viewContext.save()
            watchlist.insert(coinId)
        } catch {
            print("Error adding to watchlist: \(error)")
        }
    }
    
    private func removeFromWatchlist(_ coinId: String) {
        let request = NSFetchRequest<WatchlistItem>(entityName: "WatchlistItem")
        request.predicate = NSPredicate(format: "coinId == %@", coinId)
        
        do {
            let items = try viewContext.fetch(request)
            items.forEach { viewContext.delete($0) }
            try viewContext.save()
            watchlist.remove(coinId)
        } catch {
            print("Error removing from watchlist: \(error)")
        }
    }
    
    private func addToStockWatchlist(_ symbol: String) {
        let item = NSEntityDescription.insertNewObject(forEntityName: "StockWatchlistItem", 
                                                    into: viewContext) as! StockWatchlistItem
        item.stockSymbol = symbol
        item.dateAdded = Date()
        
        do {
            try viewContext.save()
            stockWatchlist.insert(symbol)
        } catch {
            print("Error adding to stock watchlist: \(error)")
        }
    }
    
    private func removeFromStockWatchlist(_ symbol: String) {
        let request = NSFetchRequest<StockWatchlistItem>(entityName: "StockWatchlistItem")
        request.predicate = NSPredicate(format: "stockSymbol == %@", symbol)  // Match the attribute name
        
        do {
            let items = try viewContext.fetch(request)
            items.forEach { viewContext.delete($0) }
            try viewContext.save()
            stockWatchlist.remove(symbol)
        } catch {
            print("Error removing from stock watchlist: \(error)")
        }
    }
}


// App colors
struct ColorManager {
    static var bkgColor: Color = Color(UIColor.systemBackground)
}

