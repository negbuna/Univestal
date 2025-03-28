//
//  Profile.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/8/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appData: AppData
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
                            if !appData.currentUsername.isEmpty {
                                Text(appData.currentUsername)
                                    .font(.title)
                                    .fontWeight(.semibold)
                            } else { // This is just for previews
                                Text("User")
                                    .font(.title)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Text("Member since \(appData.storedJoinDateString ?? appData.formattedCurrentYear())") // Also just for previews
                        
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
}

#Preview {
    ProfileView()
        .environmentObject(AppData())
}

extension ProfileView {
    private var defaultProfile: some View {
        ZStack {
            Circle()
              .fill(Color.secondary.opacity(0.5))
              .frame(width: 200, height: 200)
              .overlay {
                  Image(systemName: "person.fill")
                      .resizable()
                      .clipShape(RoundedRectangle(cornerRadius: 47))
                      .foregroundStyle(.tertiary)
                      .frame(width: 140, height: 140)
                      .offset(x: 0, y: 20)
              }
        }
    }
}
