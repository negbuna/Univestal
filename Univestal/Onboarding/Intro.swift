//
//  UVIntroView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct UVIntroView: View {
    
    @AppStorage("signed_in") var isLoggedIn: Bool = false
    
    var body: some View {
        
        
        ZStack {
            
            if isLoggedIn {
                HomepageView()
            } else {
                UVOnboardingViews()
            }
        } // end zstack
    }
}

#Preview {
    UVIntroView()
}
