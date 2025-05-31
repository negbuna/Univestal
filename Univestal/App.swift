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
    @StateObject private var finnhub = Finnhub()
    @StateObject private var sessionManager: SessionManager
    @StateObject private var authService: AuthenticationService
    
    init() {
        let context = persistenceController.container.viewContext
        _appData = StateObject(wrappedValue: AppData(context: context))
        
        let storage = SecureStorage()
        let tempSessionManager = SessionManager(storage: storage)
        _sessionManager = StateObject(wrappedValue: tempSessionManager)
        
        let tempAuthService = AuthenticationService(
            storage: storage,
            sessionManager: tempSessionManager
        )
        _authService = StateObject(wrappedValue: tempAuthService)
        
        CoreDataStack.shared.verifyStoreConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            Stage()
                .environmentObject(appData)
                .environmentObject(sessionManager)
                .environmentObject(authService)
                .environmentObject(tradingEnvironment)
                .environmentObject(newsService)
                .environmentObject(finnhub)
        }
    }
}

#Preview {
    Stage()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(News())
        .environmentObject(Finnhub())
}
