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
    @StateObject var news = News()
    @StateObject var alpacaModel = AlpacaModel()

    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Stage(appData: appData, crypto: crypto, news: news)
        }
        .modelContainer(sharedModelContainer)
    }
}
