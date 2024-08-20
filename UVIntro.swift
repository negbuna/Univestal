import SwiftUI

struct UVIntro: View {
    
    @AppStorage("signed_in") var isLoggedIn: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isLoggedIn {
                UVHomepage()
            } else {
                UVOnboarding()
            }
        } // end zstack
    }
}

#Preview {
    UVIntro()
}
