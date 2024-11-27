//
//  Stage.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct Stage: View {
    @ObservedObject var appData: AppData // The appData in this context is passed
    @ObservedObject var crypto: Crypto
    
    var body: some View {
        if appData.currentUserSignedIn && !appData.currentUsername.isEmpty {
            HomepageView(appData: appData, crypto: crypto)
        } else {
            PageViews(appData: appData, crypto: crypto)
        }
    }
}

#Preview {
    Stage(appData: AppData(), crypto: Crypto())
}
