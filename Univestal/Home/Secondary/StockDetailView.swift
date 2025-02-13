//
//  StockDetailView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/26/25.
//

import SwiftUI

extension Array {
    func getOrNil(at index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

struct StockDetailView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @Environment(\.dismiss) private var dismiss
    let stock: Stock
    @State private var historicalData: [PolygonBar] = []
    @State private var isLoading = true
    @State private var selectedPrice: Double?
    @State private var selectedIndex: Int?
    @State private var showTooltip = false
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: 16) {
                    StockInfoView(stock: stock)
                    if !historicalData.isEmpty {
                        StockChartView(
                            historicalData: historicalData,
                            selectedPrice: $selectedPrice,
                            selectedIndex: $selectedIndex,
                            showTooltip: $showTooltip,
                            tooltipPosition: $tooltipPosition
                        )
                    } else {
                        Text("Sparkline data is currently unavailable for this stock.")
                    }
                    
                    Spacer()
                    
                    detailedTradeButtons
                    .padding()
                }
                .padding()
            }
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
            .background(RoundedRectangle(cornerRadius: 20).opacity(0.07))
            .globeOverlay()
        }
        .task {
            await loadHistoricalData()
        }
    }
}

extension StockDetailView {
    private func loadHistoricalData() async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        environment.polygon.fetchHistoricalData(
            for: stock.symbol,
            from: endDate,
            to: startDate
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let bars):
                    self.historicalData = bars
                case .failure(let error):
                    print("Error loading historical data: \(error)")
                }
                self.isLoading = false
            }
        }
    }
    
    private var detailedTradeButtons: some View {
        HStack {
            NavigationLink(destination: BuyUI(asset: stock, environment: environment)) {
                Text("Buy")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            
            NavigationLink(destination: SellUI(asset: stock)) {
                Text("Sell")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(15)
            }
        }
    }
}

