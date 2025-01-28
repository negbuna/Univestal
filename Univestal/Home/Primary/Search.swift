//
//  Search.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/28/25.
//

import SwiftUI

struct Search: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @State var selectedTab = "crypto"
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                CryptoSearch()
                    .tabItem {
                        Image(systemName: "bitcoinsign.circle.fill")
                        Text("Crypto")
                    }
                    .tag("crypto")
                
                StockSearch()
                    .tabItem {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Stocks")
                    }
                    .tag("stocks")
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    Search()
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
}
