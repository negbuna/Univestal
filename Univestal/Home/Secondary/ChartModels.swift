//
//  ChartModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/10/25.
//

import SwiftUI
import Charts

struct StockInfoView: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Symbol: \(stock.symbol.uppercased())")
                .font(.headline)
            Text("Current Price: \(stock.price, specifier: "$%.2f")")
            Text("Change: \(stock.change, specifier: "$%.2f")")
            Text("7d % Change: \(stock.percentChange, specifier: "%.2f%%")")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.primary)
                .opacity(0.07)
        )
    }
}

struct StockChartView: View {
    let historicalData: [PolygonBar]
    @Binding var selectedPrice: Double?
    @Binding var selectedIndex: Int?
    @Binding var showTooltip: Bool
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        stockChart
    }
}

extension StockChartView {
    private func formatPrice(_ price: Double) -> String {
        if price < 0.01 { return String(format: "%.7f", price) }
        else if price < 1 { return String(format: "%.5f", price) }
        else { return String(format: "%.2f", price) }
    }
    
    private func updateSelection(value: DragGesture.Value, geometry: GeometryProxy, proxy: ChartProxy) {
        let x = value.location.x - geometry.frame(in: .local).origin.x
        if let index = proxy.value(atX: x) as Int?,
           index >= 0 && index < historicalData.count {
            selectedIndex = index
            selectedPrice = historicalData[index].close
            tooltipPosition = value.location
            showTooltip = true
        }
    }
    
    private func clearSelection() {
        selectedIndex = nil
        selectedPrice = nil
        showTooltip = false
    }
    
    var stockChart: some View {
        Chart {
            ForEach(Array(historicalData.enumerated()), id: \.offset) { index, bar in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Price", bar.close)
                )
                .foregroundStyle(
                    bar.close >= (historicalData.getOrNil(at: index-1)?.close ?? bar.close)
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
}

struct ChartContentView: View {
    let historicalData: [PolygonBar]
    @Binding var selectedPrice: Double?
    @Binding var selectedIndex: Int?
    @Binding var showTooltip: Bool
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(0..<historicalData.count, id: \.self) { index in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Price", historicalData[index].close)
                )
                .foregroundStyle(
                    historicalData[index].close >= (historicalData.getOrNil(at: index-1)?.close ?? historicalData[index].close)
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
}

extension ChartContentView {
    private func updateSelection(value: DragGesture.Value, geometry: GeometryProxy, proxy: ChartProxy) {
        let x = value.location.x - geometry.frame(in: .local).origin.x
        if let index = proxy.value(atX: x) as Int?,
           index >= 0 && index < historicalData.count {
            selectedIndex = index
            selectedPrice = historicalData[index].close
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

struct TooltipView: View {
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
