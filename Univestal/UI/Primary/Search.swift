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
    @EnvironmentObject var finnhub: Finnhub
    @Environment(\.dismiss) private var dismiss
    @State var selectedTab = "crypto"
    @State var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Crypto").tag("crypto")
                    Text("Stocks").tag("stocks")
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .padding(.horizontal)
                .padding(.bottom)
                
                if selectedTab == "crypto" {
                    CryptoSearch(searchText: $searchText)
                } else {
                    StockSearch(searchText: $searchText)
                }
            }
        }
    }
}

#Preview {
    Search()
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(Finnhub())
}
