//
//  CryptoSearch.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import SwiftUI

struct CryptoSearch: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    @State private var selectedCoinID: String? = nil
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if isLoading && environment.coins.isEmpty {
                        ProgressView()
                    } else {
                        List {
                            let _ = print("Rendering \(environment.coins.count) coins")
                            
                            ForEach(environment.coins) { coin in
                                NavigationLink(destination: CoinDetailView(coin: coin)) {
                                    CoinRow(for: coin)
                                }
                            }
                        }
                        .refreshable {
                            await environment.fetchCryptoData()
                        }
                    }
                }
            }
            .navigationTitle("Coins")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
            }
            .searchable(text: $searchText)
            .onChange(of: searchText) {
                print("Search text changed to: \(searchText)")
                Task {
                    await environment.fetchCryptoData()
                }
            }
            .task {
                if environment.coins.isEmpty {
                    await environment.fetchCryptoData()
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    CryptoSearch(searchText: .constant(""))
        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
        .environmentObject(TradingEnvironment.shared)
}

extension CryptoSearch {
    private func CoinRow(for coin: Coin) -> some View {
        HStack {
            Button(action: {
                appData.toggleWatchlist(for: coin.id)
            }) {
                Image(systemName: appData.watchlist.contains(coin.id) ? "star.fill" : "star")
                    .foregroundColor(appData.watchlist.contains(coin.id) ? .yellow : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading) {
                Text(coin.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(coin.symbol.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", coin.current_price))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(coin.price_change_percentage_24h ?? 0 >= 0 ? "+" : "")\(String(format: "%.2f", coin.price_change_percentage_24h ?? 0.00))%")
                    .font(.subheadline)
                    .foregroundColor(appData.percentColor(coin.price_change_percentage_24h ?? 0))
            }
        }
    }
}
