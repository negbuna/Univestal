//
//  UVIntroView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct UVIntroView: View {
    @AppStorage("signed_in") var isLoggedIn: Bool = false
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        
        ZStack {
            if isLoggedIn {
                HomepageView(appData: appData)
            } else {
                PageViews(appData: appData)
            }
        } // end zstack
    }
}

#Preview {
    @Previewable @EnvironmentObject var appData: AppData
    
    UVIntroView()
        .environmentObject(appData)

}
