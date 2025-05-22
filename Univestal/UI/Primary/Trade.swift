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
    @EnvironmentObject var environment: TradingEnvironment
    @EnvironmentObject var finnhub: Finnhub
    @EnvironmentObject var appData: AppData
    @State private var showMenu: Bool = false
    @State private var activeAlert: TradeAlertType?
    @State private var tradeErrorAlert: Bool = false
    @State private var isBuying: Bool = true
    @State private var selectedTimeFrame: TimeFrame = .day
    @State private var cancellables = Set<AnyCancellable>()
    @State private var tradeMode: TradeMode = .quantity
    @State private var dollarAmount: String = ""
    @State private var showingResetAlert = false
    @State private var isLoading: Bool = false
    
    enum TradeMode {
        case quantity, amount
    }

    @State private var selectedCoin: Coin?
    @State private var tradedCoin: String = ""
    @State private var tradedQuantity: String = ""

    private var holdings: [AssetHolding] {
        environment.holdings
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                portfolioHeader
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Crypto Holdings Section
                        WatchlistSection(
                            title: "Cryptocurrency Holdings",
                            isEmpty: environment.holdings.filter { $0.type == .crypto }.isEmpty,
                            content: {
                                if !environment.holdings.filter({ $0.type == .crypto }).isEmpty {
                                    ScrollView {
                                        LazyVStack(spacing: 0) {
                                            ForEach(environment.holdings.filter { $0.type == .crypto }) { holding in
                                                TradeHoldingRow(holding: holding)
                                                    .id(holding.id)
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 300)
                                }
                            }
                        )
                        
                        // Stock Holdings Section
                        WatchlistSection(
                            title: "Stock Holdings",
                            isEmpty: environment.holdings.filter { $0.type == .stock }.isEmpty
                        ) {
                            if !environment.holdings.filter({ $0.type == .stock }).isEmpty {
                                ScrollView {
                                    LazyVStack(spacing: 0) {
                                        ForEach(environment.holdings.filter { $0.type == .stock }) { holding in
                                            TradeHoldingRow(holding: holding)
                                                .id(holding.id)
                                        }
                                    }
                                }
                                .frame(maxHeight: 300)
                            }
                        }
                    }
                    .padding()
                }
            }
            .task {
                print("🔄 TradingView appeared, fetching data...")
                await environment.fetchCryptoData()
                try? await environment.fetchStockData()
            }
            .navigationTitle("Trading Simulator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink("History") {
                        PastTrades()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingResetAlert = true
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                            .foregroundStyle(.red)
                            .font(.title3)
                    }
                }
            }
            .alert("Reset Portfolio", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    try? environment.resetPortfolio()
                }
            } message: {
                Text("This will reset your portfolio balance to $100,000 and remove all trading history. This action cannot be undone.")
            }
            .globeOverlay()
            .navigationBarBackButtonHidden(true)
        }
    }

    private var portfolioHeader: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                HStack {
                    Text("Your Portfolio")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if let change = environment.portfolioChange(for: selectedTimeFrame) {
                        Text("\(change.amount >= 0 ? "+" : "")\(change.percentage, specifier: "%.1f")%")
                            .font(.subheadline)
                            .foregroundColor(change.amount >= 0 ? .green : .red)
                    }
                }
                
                HStack {
                    Text(environment.totalPortfolioValue, format: .currency(code: "USD"))
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    if let change = environment.portfolioChange(for: selectedTimeFrame) {
                        Text("\(change.amount >= 0 ? "+" : "")\(change.amount, specifier: "$%.2f")")
                            .font(.subheadline)
                            .foregroundColor(change.amount >= 0 ? .green : .red)
                    }
                }
            }
            
            Picker("Time Frame", selection: $selectedTimeFrame) {
                Text("24H").tag(TimeFrame.day)
                Text("7D").tag(TimeFrame.week)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Text("Cash Available: \(environment.portfolioBalance, specifier: "$%.2f")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    private var portfolioView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Portfolio: \(environment.totalPortfolioValue, specifier: "$%.2f")")
                    .font(.title2)
                    .bold()
                
                if let change = environment.portfolioChange(for: selectedTimeFrame) {
                    Text("\(change.amount >= 0 ? "+" : "")\(change.amount, specifier: "$%.2f") (\(change.amount >= 0 ? "+" : "")\(change.percentage, specifier: "%.1f")%)")
                        .font(.subheadline)
                        .foregroundColor(change.amount >= 0 ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
            
            Picker("Time Frame", selection: $selectedTimeFrame) {
                Text("24H").tag(TimeFrame.day)
                Text("7D").tag(TimeFrame.week)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Text("Cash Available: \(environment.portfolioBalance, specifier: "$%.2f")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 20) {
                HoldingsSection(
                    title: "Cryptocurrency Holdings",
                    isEmpty: environment.holdings.filter { $0.type == .crypto }.isEmpty,
                    type: .crypto
                ) {
                    ForEach(environment.holdings.filter { $0.type == .crypto }) { holding in
                        TradeHoldingRow(holding: holding)
                            .id(holding.id)  // Add explicit ID to ensure proper identification
                    }
                }
                
                HoldingsSection(
                    title: "Stock Holdings",
                    isEmpty: environment.holdings.filter { $0.type == .stock }.isEmpty,
                    type: .stock
                ) {
                    ForEach(environment.holdings.filter { $0.type == .stock }) { holding in
                        TradeHoldingRow(holding: holding)
                            .id(holding.id)  // Add explicit ID
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func calculateTotalPortfolioValue() -> Double {
        return environment.totalPortfolioValue
    }

    private var tradeButtons: some View {
        HStack {
            if let coin = selectedCoin {
                NavigationLink(destination: UnifiedTradeView(asset: coin, type: .buy)) {
                    Text("Buy")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                NavigationLink(destination: UnifiedTradeView(asset: coin, type: .sell)) {
                    Text("Sell")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            } else {
                Text("Select a coin to trade")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
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

enum TradeAlertType: Identifiable {
    var id: String { UUID().uuidString }
    case confirmTrade, insufficientFunds, insufficientHoldings, tradeError
    
    var title: String {
        switch self {
        case .confirmTrade: return "Confirm Trade"
        case .insufficientFunds: return "Insufficient Funds"
        case .insufficientHoldings: return "Insufficient Holdings"
        case .tradeError: return "Trade Error"
        }
    }
    
    var message: String {
        switch self {
        case .confirmTrade: return "Are you sure you want to execute this trade?"
        case .insufficientFunds: return "You don't have enough funds to complete this trade."
        case .insufficientHoldings: return "You don't have enough holdings to complete this trade."
        case .tradeError: return "An error occurred while executing the trade."
        }
    }
}

#Preview {
    TradingView()
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(AppData())
        .environmentObject(Finnhub())
}
