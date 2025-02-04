//
//  StockSearch.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/26/25.
//

// merge stock and crypto search into one view
import SwiftUI

struct StockSearch: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    var filteredStocks: [Stock] {
        if searchText.isEmpty {
            return environment.stocks
        } else {
            let results = environment.stocks.filter { $0.symbol.lowercased().contains(searchText.lowercased()) }
            return results.isEmpty ? environment.stocks.filter { $0.name.lowercased().contains(searchText.lowercased()) } : results
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else if filteredStocks.isEmpty {
                    VStack {
                        Spacer()
                        Text("No results")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding()
                        Spacer()
                    }
                } else {
                    List(filteredStocks) { stock in
                        HStack {
                            Button(action: {
                                appData.toggleStockWatchlist(for: stock.symbol)
                            }) {
                                Image(systemName: appData.stockWatchlist.contains(stock.symbol) ? "star.fill" : "star")
                                    .foregroundColor(appData.stockWatchlist.contains(stock.symbol) ? .yellow : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            NavigationLink(destination: StockDetailView(stock: stock)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(stock.symbol)
                                            .font(.headline)
                                        Text(stock.name)
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "$%.2f", stock.price))
                                            .font(.headline)
                                        Text(String(format: "%.2f%%", stock.percentChange))
                                            .font(.subheadline)
                                            .foregroundColor(stock.percentChange >= 0 ? .green : .red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
//            .navigationTitle("Stocks")
//            .navigationBarTitleDisplayMode(.inline)
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                isLoading = true
                do {
                    try await environment.fetchStockData()
                } catch PaperTradingError.apiLimitExceeded {
                    errorMessage = PaperTradingError.apiLimitExceeded.localizedDescription
                    showError = true
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                isLoading = false
            }
        }
    }
}

//#Preview {
//    StockSearch()
//        .environmentObject(AppData(context: PersistenceController.preview.container.viewContext))
//        .environmentObject(TradingEnvironment.shared)
//}
