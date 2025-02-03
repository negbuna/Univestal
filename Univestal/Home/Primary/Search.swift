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
    @State var searchText = ""
    
    var body: some View {
            NavigationStack {
                VStack {
                    // Picker stays at the top
                    Picker("", selection: $selectedTab) {
                        Text("Crypto").tag("crypto")
                        Text("Stocks").tag("stocks")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .padding(.horizontal)

                    // Display the selected view
                    if selectedTab == "crypto" {
                        CryptoSearch(searchText: $searchText)
                    } else {
                        StockSearch(searchText: $searchText)
                    }
                }
                .searchable(text: $searchText)
            }
        }
}

#Preview {
    Search()
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
}
