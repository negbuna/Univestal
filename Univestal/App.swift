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
    @StateObject var appData = AppData()
    @StateObject var tradingEnvironment = TradingEnvironment.shared

    var body: some Scene {
        WindowGroup {
            Stage(appData: appData)
            .environmentObject(appData)
            .environmentObject(tradingEnvironment)
        }
    }
}
