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
    @ObservedObject var news: News
    
    var body: some View {
        if appData.currentUserSignedIn && !appData.currentUsername.isEmpty {
            HomepageView(appData: appData, crypto: crypto, news: news)
        } else {
            PageViews(appData: appData, crypto: crypto, news: news)
        }
    }
}

#Preview {
    Stage(appData: AppData(), crypto: Crypto(), news: News())
}
