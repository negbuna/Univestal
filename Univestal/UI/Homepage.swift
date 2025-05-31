//
//  HomepageView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct HomepageView: View {
    @EnvironmentObject private var appData: AppData
    @EnvironmentObject private var sessionManager: SessionManager
    
    var body: some View {
        TabView {
            NavigationStack {
                UVHubView()
            }
            .tabItem {
                Label("Hub", systemImage: "globe")
            }
            
            NavigationStack {
                Watchlist()
            }
            .tabItem {
                Label("Label", systemImage: "star.fill")
            }
            
            NavigationStack {
                TradingView()
            }
            .tabItem {
                Label("Trade", systemImage: "chart.pie.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Learn", systemImage: "puzzlepiece.extension.fill")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Me", systemImage: "person.fill")
            }
        }
        .accentColor(.blue)
    }
}

#Preview {
    HomepageView()
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(SessionManager())
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(News())
        .environmentObject(Finnhub())
}
