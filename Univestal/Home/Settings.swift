//
//  UVSettingsView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/7/24.
//

import SwiftUI

struct UVSettingsView: View {
    
    //state vars
    @AppStorage("username") var currentUsername: String?
    @AppStorage("age") var currentUserAge: Int?
    @AppStorage("signed_in") var currentUserSignedIn: Bool = false
    @AppStorage("hashed_password") var storedHashedPassword: String?
    
    @State private var showAlertSignout: Bool = false
    @State private var showAlertDelete: Bool = false
    @State private var shouldShowIntroView: Bool = false // Control navigation
    
    var body: some View {
        
        NavigationView {
            ZStack {
                ColorManager.bkgColor
                    .ignoresSafeArea()
                List {
                    Section(header: Text("App")) {
                        NavigationLink(destination: PrivacyPolicyView()) {
                            Text("Privacy Policy")
                        }
                        NavigationLink(destination: ReviewView()) {
                            Text("Leave a Review")
                        }
                    }
                    Section(header: Text("Profile")) {
                        Button(action: {
                            showAlertSignout.toggle()
                            
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                        .alert(isPresented: $showAlertSignout) {
                            Alert(
                                title: Text("Are you sure?"),
                                primaryButton: .cancel(Text("Stay Signed In")),
                                secondaryButton: .destructive(Text("Sign Out")) {
                                    signOut()
                                    currentUserSignedIn = false
                                }
                            )
                        }
                        
                        Button(action: {
                            showAlertDelete.toggle()
                        }) {
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                        .alert(isPresented: $showAlertDelete) {
                            Alert(
                                title: Text("Are you sure you want to delete your account?"),
                                message: Text("This action cannot be undone."),
                                primaryButton: .cancel(Text("No")),
                                secondaryButton: .destructive(Text("Delete Account")) {
                                    deleteAccount()
                                    currentUserSignedIn = false
                                }
                            )
                        }
                    } // end section header
                } // end list
                .navigationTitle("Settings")
            }
        } // end nav stack
    } // end body
    
    private func signOut() {
        currentUsername = nil
        currentUserAge = nil
        currentUserSignedIn = false
    }
    
    private func deleteAccount() {
        currentUsername = nil
        currentUserAge = nil
        currentUserSignedIn = false
        storedHashedPassword = nil

        // Additional local data cleanup if necessary
    }
}


struct UVSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        UVSettingsView()
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy Content Goes Here")
            .navigationTitle("Privacy Policy")
    }
}

struct ReviewView: View {
    var body: some View {
        Text("Review Content Goes Here")
            .navigationTitle("Review")
    }
}
