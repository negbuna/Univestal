//
//  Trade.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/9/24.
//

import SwiftUI
import Combine
import CoreData

struct TradingView: View {
    @EnvironmentObject private var environment: TradingEnvironment
    @EnvironmentObject var finnhub: Finnhub
    @EnvironmentObject var appData: AppData
    @State private var showMenu: Bool = false
    @State private var activeAlert: TradeAlertType?
    @State private var tradeErrorAlert: Bool = false
    @State private var isBuying: Bool = true
    @State private var showingResetAlert = false
    
    // Portfolio stats computed properties
    private var portfolioValue: Double {
        environment.totalPortfolioValue
    }
    
    private var portfolioChange: (amount: Double, percentage: Double)? {
        environment.portfolioChange(for: environment.selectedTimeFrame)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio Header
                    portfolioHeader
                    
                    // Holdings Sections
                    Group {
                        holdingsSection(
                            title: "Crypto Holdings",
                            holdings: environment.holdings.filter { $0.type == .crypto }
                        )
                        
                        holdingsSection(
                            title: "Stock Holdings",
                            holdings: environment.holdings.filter { $0.type == .stock }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Trading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingResetAlert = true }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Reset Portfolio", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        try environment.resetPortfolio()
                    }
                }
            } message: {
                Text("Are you sure you want to reset your portfolio?")
            }
        }
    }
    
    private var portfolioHeader: some View {
        VStack(spacing: 12) {
            Text("Portfolio Value")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(portfolioValue, format: .currency(code: "USD"))
                .font(.title.bold())
            
            if let change = portfolioChange {
                HStack(spacing: 4) {
                    Image(systemName: change.amount >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(change.amount, format: .currency(code: "USD"))")
                    Text("(\(change.percentage, specifier: "%.1f")%)")
                }
                .foregroundColor(change.amount >= 0 ? .green : .red)
                .font(.subheadline)
            }
            
            Picker("Time Frame", selection: Binding(
                get: { environment.selectedTimeFrame },
                set: { environment.updateTimeFrame($0) }
            )) {
                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func holdingsSection(title: String, holdings: [AssetHolding]) -> some View {
        WatchlistSection(
            title: title,
            isEmpty: holdings.isEmpty
        ) {
            LazyVStack(spacing: 0) {
                if holdings.isEmpty {
                    EmptyView()
                } else {
                    ForEach(holdings) { holding in
                        TradeHoldingRow(holding: holding)
                    }
                }
            }
        }
    }
}

struct TradeHoldingRow: View {
    let holding: AssetHolding
    @EnvironmentObject var environment: TradingEnvironment
    
    var body: some View {
        if let asset = assetForHolding {
            NavigationLink(destination: UnifiedTradeView(asset: asset, type: .sell)) {
                HoldingRowContent(holding: holding)
            }
        } else {
            HoldingRowContent(holding: holding)
                .opacity(0.5)
                .overlay(
                    Text("Asset data unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
        }
    }
    
    private var assetForHolding: Tradeable? {
        // Add debug logging
        print("DEBUG: Looking up asset for holding - Type: \(holding.type), ID: \(holding.id)")
        
        switch holding.type {
        case .crypto:
            let asset = environment.coins.first { $0.id == holding.id }
            print("DEBUG: Crypto lookup result: \(asset?.id ?? "not found")")
            return asset
        case .stock:
            let asset = environment.stocks.first { $0.symbol == holding.symbol }
            print("DEBUG: Stock lookup result: \(asset?.symbol ?? "not found")")
            return asset
        }
    }
}

struct HoldingRowContent: View {
    let holding: AssetHolding
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(holding.symbol.uppercased())
                    .font(.headline)
                Text("\(AssetFormatter.format(quantity: holding.quantity)) units")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(holding.totalValue, format: .currency(code: "USD"))
                    .font(.headline)
                
                HStack(spacing: 2) {
                    // Show both dollar and percentage change
                    Text(holding.profitLoss >= 0 ? "+" : "")
                        .foregroundColor(holding.profitLoss >= 0 ? .green : .red)
                    Text(abs(holding.profitLoss), format: .currency(code: "USD"))
                        .foregroundColor(holding.profitLoss >= 0 ? .green : .red)
                    
                    // Add percentage change
                    if holding.purchasePrice > 0 {
                        let percentChange = ((holding.currentPrice - holding.purchasePrice) / holding.purchasePrice) * 100
                        Text("(\(percentChange >= 0 ? "+" : "")\(String(format: "%.1f", percentChange))%)")
                            .foregroundColor(percentChange >= 0 ? .green : .red)
                            .font(.subheadline)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    TradingView()
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(AppData())
        .environmentObject(Finnhub())
}
