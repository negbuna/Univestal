//
//  Profile.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/8/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    
    @State var isEditable: Bool = true
    @State var image: UIImage?
    @State private var isProfileUpdated = false
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorManager.bkgColor
                    .ignoresSafeArea()
                
                VStack(alignment: .center) {
                    VStack(alignment: .center, spacing: 40) {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                                .shadow(color: Color.primary.opacity(0.5), radius: 15)
                                .onTapGesture {
                                    self.showImagePicker = true
                                }
                        } else {
                            defaultProfile
                                .onTapGesture {
                                    self.showImagePicker = true
                                }
                        }
                        
                        if isEditable {
                            if let username = sessionManager.currentUser?.username {
                                Text(username)
                                    .font(.title)
                                    .fontWeight(.semibold)
                            } else {
                                Text("User")
                                    .font(.title)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // Use a computed property for the join date
                        Text("Member since \(joinDate)")
                        
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                    
                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $image)
            }
        }
    }
    
    private var defaultProfile: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .foregroundColor(.gray)
    }
    
    private var joinDate: String {
        // Format current date as fallback
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionManager())
}
