//
//  UVProfileView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/8/24.
//

import SwiftUI

struct UVProfileView: View {
    
    @AppStorage("username") var currentUsername: String?
    @AppStorage("joindate") var storedJoinDateString: String?
    
    @State var isEditable: Bool = true
    @State var image: UIImage?
    @State private var isProfileUpdated = false
    @State private var showImagePicker = false
    
    func formattedCurrentYear() -> String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy" // Year format (yyyy for full year)
      return dateFormatter.string(from: Date.now)
    }
    
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
                              .scaledToFit()
                              .frame(width: 200, height: 200)
                              .clipShape(Circle())
                              .shadow(color: Color.primary.opacity(0.5), radius: 15)
                          } else {
                            Circle()
                              .fill(Color.secondary.opacity(0.5))
                              .frame(width: 200, height: 200)
                              .overlay {
                                  Image(systemName: "person.fill")
                                      .resizable()
                                      .clipShape(Circle())
                                      .foregroundStyle(.tertiary)
                                      .frame(width: 140, height: 140)
                                      .offset(x: 0, y: 20)
                              }
                              .onTapGesture {
                                self.showImagePicker = true
                              }
                          }
                        
                        if isEditable {
                            Text(currentUsername ?? "Univestal User")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Member since \(storedJoinDateString ?? formattedCurrentYear())")
                        
                        
                        Spacer()
                       
                        
                    } // end hstack for pfp and username
                    .padding()
                    
                    Divider()
                    
                    
                    
                    Spacer()
                }
                
            }
            .navigationTitle("Profile")
            .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: UVSettingsView()) {
                            Image(systemName: "gearshape.fill")
                        
                    }
                }
            }
        }
    }
}

#Preview {
    UVProfileView()
}
