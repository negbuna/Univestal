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
    @ObservedObject var tradingManager: PaperTradingManager
    @ObservedObject var simulator: PaperTradingSimulator
    @Binding var tradeUUID: UUID?

    
    var body: some View {
        if appData.currentUserSignedIn && !appData.currentUsername.isEmpty {
            HomepageView(
                appData: appData, crypto: crypto, news: news, tradingManager: tradingManager,
                simulator: PaperTradingSimulator(initialBalance: 100_000.0),
                tradeUUID: $tradeUUID
            )
        } else {
            PageViews(
                appData: appData,
                crypto: crypto,
                news: news,
                tradingManager: tradingManager,
                simulator: PaperTradingSimulator(initialBalance: 100_000.0),
                tradeUUID: $tradeUUID
            )
        }
    }
}

#Preview {
    @Previewable @State var tradeUUID: UUID? = UUID() // UUID for the preview
    
    Stage(
        appData: AppData(),
        crypto: Crypto(),
        news: News(),
        tradingManager: PaperTradingManager(crypto: Crypto(), simulator: PaperTradingSimulator(initialBalance: 100_000.0)),
        simulator: PaperTradingSimulator(initialBalance: 100_000.0),
        tradeUUID: $tradeUUID
    )
}
