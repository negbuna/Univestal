//
//  StockDetailView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/26/25.
//

import SwiftUI
import Charts

extension Array {
    func getOrNil(at index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

struct StockDetailView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    let stock: Stock
    @State private var historicalData: [PolygonBar] = []
    @State private var isLoading = true
    
    // Make component views
    private struct StockInfoView: View {
        let stock: Stock
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Symbol: \(stock.symbol.uppercased())")
                    .font(.headline)
                Text("Current Price: \(stock.price, specifier: "$%.2f")")
                Text("Change: \(stock.change, specifier: "%.2f")")
                    .foregroundColor(stock.change >= 0 ? .green : .red)
                Text("% Change: \(stock.percentChange, specifier: "%.2f%%")")
                    .foregroundColor(stock.percentChange >= 0 ? .green : .red)
            }
        }
    }
    
    private struct PriceChartView: View {
        let historicalData: [PolygonBar]
        
        var body: some View {
            Chart {
                ForEach(Array(historicalData.enumerated()), id: \.offset) { index, bar in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Price", bar.c)
                    )
                    .foregroundStyle(
                        bar.c >= (historicalData.getOrNil(at: index-1)?.c ?? bar.c) 
                        ? .green : .red
                    )
                }
            }
            .frame(height: 200)
            .chartXAxis(.hidden)
        }
    }
    
    //MARK: Main View
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StockInfoView(stock: stock)
                
                if !historicalData.isEmpty {
                    PriceChartView(historicalData: historicalData)
                }
            }
            .padding()
        }
        .navigationTitle(stock.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHistoricalData()
        }
    }
    
    private func loadHistoricalData() async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        environment.polygon.fetchHistoricalData(
            for: stock.symbol,
            from: startDate,
            to: endDate
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
}
