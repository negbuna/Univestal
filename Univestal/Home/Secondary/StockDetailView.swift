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
                    }
                    
                    HStack {
                        NavigationLink(destination: BuyUI(asset: stock)) {
                            Text("Buy")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        NavigationLink(destination: SellUI(asset: stock)) {
                            Text("Sell")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
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
                // Keep any existing toolbar items
            }
        }
        .task {
            await loadHistoricalData()
        }
    }
}

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
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).foregroundStyle(.primary))
    }
}

private struct StockChartView: View {
    let historicalData: [PolygonBar]
    @Binding var selectedPrice: Double?
    @Binding var selectedIndex: Int?
    @Binding var showTooltip: Bool
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("7 Day Price History")
                .font(.headline)
            
            ChartContentView(
                historicalData: historicalData,
                selectedPrice: $selectedPrice,
                selectedIndex: $selectedIndex,
                showTooltip: $showTooltip,
                tooltipPosition: $tooltipPosition
            )
        }
    }
}

private struct ChartContentView: View {
    let historicalData: [PolygonBar]
    @Binding var selectedPrice: Double?
    @Binding var selectedIndex: Int?
    @Binding var showTooltip: Bool
    @Binding var tooltipPosition: CGPoint
    
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
            
            if let selectedIndex = selectedIndex,
               let selectedPrice = selectedPrice {
                RuleMark(x: .value("Selected", selectedIndex))
                    .foregroundStyle(.gray.opacity(0.3))
                
                PointMark(
                    x: .value("Selected", selectedIndex),
                    y: .value("Price", selectedPrice)
                )
                .foregroundStyle(.blue)
            }
        }
        .frame(height: 200)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                let price = value.as(Double.self) ?? 0
                AxisValueLabel { Text(formatPrice(price)) }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelection(value: value, geometry: geometry, proxy: proxy)
                            }
                            .onEnded { _ in
                                clearSelection()
                            }
                    )
                    .overlay {
                        if showTooltip {
                            TooltipView(
                                selectedIndex: selectedIndex,
                                selectedPrice: selectedPrice,
                                position: tooltipPosition
                            )
                        }
                    }
            }
        }
    }
    
    private func updateSelection(value: DragGesture.Value, geometry: GeometryProxy, proxy: ChartProxy) {
        let x = value.location.x - geometry.frame(in: .local).origin.x
        if let index = proxy.value(atX: x) as Int?,
           index >= 0 && index < historicalData.count {
            selectedIndex = index
            selectedPrice = historicalData[index].c
            tooltipPosition = value.location
            showTooltip = true
        }
    }
    
    private func clearSelection() {
        selectedIndex = nil
        selectedPrice = nil
        showTooltip = false
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price < 0.01 { return String(format: "%.7f", price) }
        else if price < 1 { return String(format: "%.5f", price) }
        else { return String(format: "%.2f", price) }
    }
}

private struct TooltipView: View {
    let selectedIndex: Int?
    let selectedPrice: Double?
    let position: CGPoint
    
    var body: some View {
        if let index = selectedIndex,
           let price = selectedPrice {
            let date = Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(date))
                    .font(.caption)
                Text("$\(formatPrice(price))")
                    .font(.caption.bold())
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 4)
            )
            .position(x: position.x, y: position.y - 50)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price < 0.01 { return String(format: "%.7f", price) }
        else if price < 1 { return String(format: "%.5f", price) }
        else { return String(format: "%.2f", price) }
    }
}

extension StockDetailView {
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

