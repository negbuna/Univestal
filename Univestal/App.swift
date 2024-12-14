//
//  App.swift
//  Univestal
//
//  Created by Nathan Egbuna on 6/18/24.
//

import SwiftUI
import SwiftData

@main
struct UnivestalApp: App {
    @StateObject var appData = AppData()
    @StateObject var crypto = Crypto()
    @StateObject var simulator = PaperTradingSimulator(initialBalance: 100_000.0)
    @StateObject var news = News()
    @StateObject var tradingManager: PaperTradingManager
    @State private var tradeUUID: UUID? = UUID() // Initialize with a UUID

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
            let crypto = Crypto()
        let simulator = PaperTradingSimulator(initialBalance: 100_000.0)
            _crypto = StateObject(wrappedValue: crypto)
            _simulator = StateObject(wrappedValue: simulator)
            _tradingManager = StateObject(wrappedValue: PaperTradingManager(crypto: crypto, simulator: simulator))
        }

    var body: some Scene {
        WindowGroup {
            Stage(appData: appData, crypto: crypto, news: news, tradingManager: tradingManager, simulator: simulator, tradeUUID: $tradeUUID)
        }
        .modelContainer(sharedModelContainer)
    }
}
