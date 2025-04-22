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
    @State private var selectedCoin: Coin?
    @State private var tradeErrorAlert: Bool = false
    @State private var isBuying: Bool = true
    @State private var selectedTimeFrame: TimeFrame = .day
    @State private var cancellables = Set<AnyCancellable>()
    @State private var tradeMode: TradeMode = .quantity
    @State private var dollarAmount: String = ""
    @State private var showingResetAlert = false
    @State private var selectedAssetType: AssetType = .crypto
    @State private var isLoading: Bool = false
    
    enum TradeMode {
        case quantity, amount
    }
    
    var filteredCoins: [Coin] {
        if tradedCoin.isEmpty {
            return environment.coins
        } else {
            return environment.filteredCoins(matching: tradedCoin)
        }
    }
    
    @State private var tradedCoin: String = ""
    @State private var tradedQuantity: String = ""

    private var holdings: [AssetHolding] {
        environment.holdings
    }

    private var watchlistStocks: [Stock] {
        environment.stocks.filter { stock in
            appData.stockWatchlist.contains(stock.symbol)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Asset Type", selection: $selectedAssetType) {
                    Text("Crypto").tag(AssetType.crypto)
                    Text("Stocks").tag(AssetType.stock)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(UIColor.systemBackground))
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            switch selectedAssetType {
                            case .crypto:
                                if environment.coins.isEmpty {
                                    ContentUnavailableView(
                                        "No Coins Available",
                                        systemImage: "bitcoinsign.circle",
                                        description: Text("Check your internet connection")
                                    )
                                } else {
                                    ForEach(environment.coins, id: \.id) { coin in
                                        CoinWatchlistRow(coin: coin)
                                    }
                                }
                            case .stock:
                                if watchlistStocks.isEmpty {
                                    ContentUnavailableView(
                                        "No Stocks Available",
                                        systemImage: "chart.bar.xaxis",
                                        description: Text("Check your internet connection")
                                    )
                                } else {
                                    ForEach(watchlistStocks, id: \.symbol) { stock in
                                        StockWatchlistRow(stock: stock)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
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

    private var tradeMenuView: some View {
        Group {
            if showMenu {
                VStack {
                    Text("Trade")
                        .foregroundStyle(.secondary)
                        .bold()

                    Divider()

                    TradeMenuView(
                        selectedCoin: $selectedCoin,
                        tradedCoin: $tradedCoin,
                        tradedQuantity: $tradedQuantity
                    )

                    Divider()

                    buttons
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 10)
                )
                .transition(.move(edge: .bottom))
            }
        }
    }

    private var buttons: some View {
        HStack {
            Button("Cancel") {
                withAnimation(.easeInOut) {
                    showMenu = false
                }
            }
            .foregroundStyle(.red)
            .bold()

            Spacer()

            Button("Confirm") {
                executeTrade()
            }
            .foregroundStyle(.green)
            .bold()
        }
        .padding(.horizontal)
        .alert(item: $activeAlert) { alertType in
            Alert(
                title: Text(alertType.title),
                message: Text(alertType.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func executeTrade() {
        guard let coin = selectedCoin,
              let quantity = Double(tradedQuantity) else {
            activeAlert = .tradeError
            return
        }

        do {
            if isBuying {
                try environment.executeTrade(
                    coinId: coin.id,
                    symbol: coin.symbol,
                    name: coin.name,
                    quantity: quantity,
                    currentPrice: coin.current_price
                )
            } else {
                try environment.executeSell(
                    coinId: coin.id,
                    symbol: coin.symbol,
                    name: coin.name,
                    quantity: quantity,
                    currentPrice: coin.current_price
                )
            }
            
            withAnimation(.easeInOut) {
                showMenu = false
            }
            
            // Reset fields
            selectedCoin = nil
            tradedCoin = ""
            tradedQuantity = ""
        } catch PaperTradingError.insufficientBalance {
            activeAlert = .insufficientFunds
        } catch PaperTradingError.insufficientHoldings {
            activeAlert = .insufficientHoldings
        } catch {
            activeAlert = .tradeError
            print("Trade error: \(error)")
        }
    }

    private func startPeriodicFetching() {
        Task {
            await environment.fetchCryptoData()
        }
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

struct TradeMenuView: View {
    @EnvironmentObject var environment: TradingEnvironment
    @Binding var selectedCoin: Coin?
    @Binding var tradedCoin: String
    @Binding var tradedQuantity: String
    
    var filteredCoins: [Coin] {
        if tradedCoin.isEmpty {
            return environment.coins
        } else {
            return environment.filteredCoins(matching: tradedCoin)
        }
    }

    var body: some View {
        VStack {
            TextField("Enter Coin", text: $tradedCoin)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Quantity", text: $tradedQuantity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !tradedCoin.isEmpty {
                Picker("Select a Coin", selection: $selectedCoin) {
                    ForEach(filteredCoins, id: \.id) { coin in
                        Text(coin.name)
                            .tag(coin as Coin?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedCoin) {
                    if let coin = selectedCoin {
                        tradedCoin = coin.name
                    }
                }
                if let coin = selectedCoin,
                   let quantity = Double(tradedQuantity),
                   quantity > 0 {
                    VStack(spacing: 8) {
                        Text("Trade Summary")
                            .font(.headline)
                        Text("\(quantity) \(coin.symbol.uppercased()) = \(String(format: "$%.2f", coin.current_price * quantity))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGroupedBackground))
                    )
                }
            }
        }
        .padding()
        .onAppear {
            tradedCoin = ""
            tradedQuantity = ""
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
                .opacity(0.5) // Visual indication that the asset is unavailable
        }
    }
    
    private var assetForHolding: Tradeable? {
        if holding.type == .crypto {
            return environment.coins.first { $0.id == holding.id }
        } else {
            return environment.stocks.first { $0.symbol == holding.symbol }
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
                Text(holding.profitLoss >= 0 ? "+" : "-")
                    .foregroundColor(holding.profitLoss >= 0 ? .green : .red) +
                Text(abs(holding.profitLoss), format: .currency(code: "USD"))
                    .foregroundColor(holding.profitLoss >= 0 ? .green : .red)
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
