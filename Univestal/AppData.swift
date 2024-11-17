//
//  AppData.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/14/24.
//

import SwiftUI
import Combine

// Shared state model
class AppData: ObservableObject {
    @Published var onboardingState: Int = 0
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var showLoginButton: Bool = false
    @Published var confirmPassword: String = ""
    @Published var isButtonDisabled: Bool = true
    @Published var invalidText: String = ""
}

// App colors
struct ColorManager {
    static var bkgColor: Color = Color(UIColor.systemBackground)
    // Add more static variables as needed
}

