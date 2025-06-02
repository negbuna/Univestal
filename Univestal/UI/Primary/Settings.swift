//
//  Settings.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/7/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var showAlertSignout = false
    @State private var showAlertDelete = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button(role: .destructive) {
                        showAlertSignout.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                    .alert(isPresented: $showAlertSignout) {
                        Alert(
                            title: Text("Are you sure?"),
                            primaryButton: .cancel(Text("Stay Signed In")),
                            secondaryButton: .destructive(Text("Sign Out")) {
                                sessionManager.clearSession()
                            }
                        )
                    }
                }
                
                Section(header: Text("App")) {
                    NavigationLink(destination: PrivacyPolicy()) {
                        Text("Privacy Policy")
                    }
                    Button(action: {
                        openAppStore()
                    }) {
                        Text("Send Feedback")
                    }
                }
                
                Section(header: Text("Danger Zone")) {
                    Button(action: {
                        showAlertDelete.toggle()
                    }) {
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showAlertDelete) {
                        deleteAccountAlert
                    }
                } // end section header
            } // end list
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
            }
        } // end nav stack
    } // end body
    
    private func openAppStore() {
        let appStoreURL = URL(string: "https://apps.apple.com/app/com.negbuna.Univestal")!
        //let betaURL = URL(string: "https://testflight.apple.com/join/43RrhW8V")!
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    private func handleAccountDeletion() {
        Task {
            do {
                if let username = authService.sessionManager.currentUser?.username {
                    try await authService.deleteAccount(username: username)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    var deleteAccountAlert: Alert {
        Alert(
            title: Text("Are you sure?"),
            message: Text("You will lose all data. This action cannot be undone."),
            primaryButton: .cancel(Text("No")),
            secondaryButton: .destructive(Text("Delete Account")) {
                handleAccountDeletion()
            }
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(SessionManager())
        .environmentObject(AuthenticationService(
            storage: SecureStorage(),
            sessionManager: SessionManager()
        ))
}
