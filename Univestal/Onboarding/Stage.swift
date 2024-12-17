//
//  Stage.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct Stage: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @Binding var tradeUUID: UUID?
    
    var body: some View {
        if appData.currentUserSignedIn && !appData.currentUsername.isEmpty {
            HomepageView(tradeUUID: $tradeUUID)
        } else {
            PageViews(tradeUUID: $tradeUUID)
        }
    }
}

#Preview {
    @Previewable @State var tradeUUID: UUID? = UUID() // UUID for the preview
    
    Stage(tradeUUID: $tradeUUID)
    .environmentObject(AppData())
        .environmentObject(TradingEnvironment.shared)
}

