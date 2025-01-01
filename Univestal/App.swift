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
    let persistenceController = PersistenceController.shared
    @StateObject private var appData: AppData
    @StateObject private var tradingEnvironment = TradingEnvironment.shared
    @StateObject private var newsService = News()
    
    init() {
        let context = persistenceController.container.viewContext
        _appData = StateObject(wrappedValue: AppData(context: context))
    }

    var body: some Scene {
        WindowGroup {
            Stage()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appData)
                .environmentObject(tradingEnvironment)
                .environmentObject(newsService)
                .onAppear {
                    tradingEnvironment.crypto.fetchCoins()
                }
        }
    }
}

#Preview {
    Stage()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(News())
}
