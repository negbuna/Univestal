//
//  UVSettingsView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/7/24.
//

import SwiftUI

struct UVSettingsView: View {
    @EnvironmentObject var appData: AppData    
    
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
                        NavigationLink(destination: PrivacyPolicy()) {
                            Text("Privacy Policy")
                        }
                        Button(action: {
                            openAppStore()
                        }) {
                            Text("Send Feedback")
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
                                    appData.signOut()
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
                                title: Text("Are you sure?"),
                                message: Text("You will lose all data. This action cannot be undone."),
                                primaryButton: .cancel(Text("No")),
                                secondaryButton: .destructive(Text("Delete Account")) {
                                    appData.deleteAccount()
                                }
                            )
                        }
                    } // end section header
                } // end list
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
            }
        } // end nav stack
    } // end body
    
    private func openAppStore() {
        //let appStoreURL = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")! // Replace YOUR_APP_ID later
        let betaURL = URL(string: "itms-beta://testflight.apple.com/join/43RrhW8V")!
        if UIApplication.shared.canOpenURL(betaURL) {
            UIApplication.shared.open(betaURL, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    UVSettingsView()
        .environmentObject(AppData())
}
