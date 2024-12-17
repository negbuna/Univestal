//
//  App.swift
//  Univestal
//
//  Created by Nathan Egbuna on 6/18/24.
//

import SwiftUI
import CoreData

@main
struct UnivestalApp: App {
    @StateObject private var appData = AppData()
    @StateObject private var tradingEnvironment = TradingEnvironment.shared
    @StateObject private var newsService = News()

    var body: some Scene {
        WindowGroup {
            Stage()
                .environmentObject(appData)
                .environmentObject(tradingEnvironment)
                .environmentObject(newsService)
                .onAppear {
                    // Optional: Initialize any required data
                    tradingEnvironment.crypto.fetchCoins()
                }
        }
    }
}

#Preview {
    Stage()
        .environmentObject(AppData())
        .environmentObject(News())
        .environmentObject(TradingEnvironment.shared)
}
