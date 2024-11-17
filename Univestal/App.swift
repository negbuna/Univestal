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
    
    // Defers the initialization until appData is ready
    lazy var uvf: UVFunctions = {
        let functions = UVFunctions(appData: appData)
        functions.refreshUserSet() // Initialize the set with the stored data
        return functions
    }()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            UVIntroView()
                .environmentObject(appData)
        }
        .modelContainer(sharedModelContainer)
    }
}
