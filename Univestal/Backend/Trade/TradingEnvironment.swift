//
//  TradingEnvironment.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/14/25.
//

import SwiftUI
import CoreData

@MainActor
class TradingEnvironment: ObservableObject {
    static let shared = TradingEnvironment()
    private let coreDataStack = CoreDataStack.shared
    private let dataManager = DataManager.shared
    
    @Published var currentPortfolio: CDPortfolio?
    @Published var stocks: [Stock] = []
    @Published var coins: [Coin] = []
    
    private struct PendingTransaction {
        let type: TradeType
        let asset: Tradeable
        let quantity: Double
        let price: Double
        let timestamp: Date
    }
    
    @Published private(set) var pendingTransaction: PendingTransaction?
    @Published private(set) var transactionStatus: TransactionStatus?
    
    private init() {
        setupPortfolio()
        setupDataSubscriptions()
    }
    
    private func setupDataSubscriptions() {
        dataManager.$stocks
            .assign(to: &$stocks)
        
        dataManager.$coins
            .assign(to: &$coins)
    }
    
    private func setupPortfolio() {
        let fetchRequest: NSFetchRequest<CDPortfolio> = CDPortfolio.fetchRequest()
        
        do {
            let portfolios = try coreDataStack.context.fetch(fetchRequest)
            if let existingPortfolio = portfolios.first {
                self.currentPortfolio = existingPortfolio
            } else {
                let newPortfolio = CDPortfolio(context: coreDataStack.context)
                newPortfolio.balance = 100_000 // Initial balance
                try coreDataStack.context.save()
                self.currentPortfolio = newPortfolio
            }
        } catch {
            print("Error setting up portfolio: \(error)")
        }
    }

    // Portfolio properties
    var portfolioBalance: Double {
        currentPortfolio?.balance ?? 0.0
    }

    var totalPortfolioValue: Double {
        let holdingsValue = holdings.reduce(0.0) { $0 + $1.totalValue }
        return portfolioBalance + holdingsValue
    }

    // MARK: - Trading Methods
    private func validateTrade(amount: Double, price: Double, type: TradeType) throws {
        // Minimum trade amount ($1)
        guard amount * price >= 1.0 else {
            throw TradeInputError.minimumTradeAmount(minimum: 1.0)
        }
        
        // Maximum trade amount ($1M)
        guard amount * price <= 1_000_000 else {
            throw TradeInputError.maximumTradeAmount(maximum: 1_000_000)
        }
        
        // Validate quantity increments
        let increment = 0.0001 // Minimum increment
        let roundedAmount = (amount / increment).rounded() * increment
        guard abs(roundedAmount - amount) < 0.00001 else {
            throw TradeInputError.invalidIncrement(increment: increment)
        }
        
        // Check if price has changed significantly (>1%)
        if let holding = currentHolding,
           abs((price - holding.currentPrice) / holding.currentPrice) > 0.01 {
            throw TradeInputError.priceChanged(newPrice: price)
        }
    }
    
    func executeTrade(coinId: String, symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
        try validateTrade(amount: quantity, price: currentPrice, type: .buy)
        
        let totalCost = currentPrice * quantity
        
        guard let portfolio = currentPortfolio,
              portfolio.balance >= totalCost else {
            throw PaperTradingError.insufficientBalance
        }
        
        let trade = CDTrade(context: coreDataStack.context)
        trade.id = UUID()
        trade.coinId = coinId
        trade.coinSymbol = symbol
        trade.coinName = name
        trade.quantity = quantity
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.currentPrice = currentPrice
        trade.portfolio = portfolio
        
        portfolio.balance -= totalCost
        
        try coreDataStack.context.save()
    }
    
    func executeSell(coinId: String, symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
        try validateTrade(amount: quantity, price: currentPrice, type: .sell)
        
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "coinId == %@", coinId)
        
        guard let trades = try? coreDataStack.context.fetch(fetchRequest),
              let portfolio = currentPortfolio else {
            throw PaperTradingError.generalError
        }
        
        let totalHoldings = trades.reduce(0.0) { $0 + $1.quantity }
        guard totalHoldings >= quantity else {
            throw PaperTradingError.insufficientHoldings
        }
        
        let trade = CDTrade(context: coreDataStack.context)
        trade.id = UUID()
        trade.coinId = coinId
        trade.coinSymbol = symbol
        trade.coinName = name
        trade.quantity = -quantity
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.currentPrice = currentPrice
        trade.portfolio = portfolio
        
        portfolio.balance += (currentPrice * quantity)
        try coreDataStack.context.save()
    }

    func portfolioChange(for timeFrame: TimeFrame) -> (amount: Double, percentage: Double)? {
        let holdings = self.holdings
        guard !holdings.isEmpty else { return nil }
        
        let totalChange = holdings.reduce(0.0) { $0 + $1.profitLoss }
        let totalValue = holdings.reduce(0.0) { $0 + $1.totalValue }
        let percentageChange = totalValue > 0 ? (totalChange / totalValue) * 100 : 0
        
        return (totalChange, percentageChange)
    }

    func fetchStockData() async throws {
        let symbols = Storage().commonStocks
        let stocks = try await Finnhub.shared.fetchStocks(symbols: symbols)
        await MainActor.run {
            self.stocks = stocks
        }
    }
    
    func fetchCryptoData() async {
        let crypto = Crypto()
        await crypto.fetchCoins()
        await MainActor.run {
            self.coins = crypto.coins
        }
    }
    
    // Add computed property for filtered coins
    func filteredCoins(matching text: String) -> [Coin] {
        if text.isEmpty {
            return coins
        }
        return coins.filter { $0.name.lowercased().contains(text.lowercased()) }
    }
    
    // Add coin lookup method
    func findCoin(byId id: String) -> Coin? {
        return coins.first { $0.id == id }
    }
    
    private func executeTrade(transaction: PendingTransaction) async throws {
        transactionStatus = .processing
        
        // Validate price hasn't changed more than 1%
        let currentPrice = transaction.asset.currentPrice
        let priceChange = abs((currentPrice - transaction.price) / transaction.price)
        
        if priceChange > 0.01 {
            transactionStatus = .priceChanged(newPrice: currentPrice)
            throw TradeError.priceChanged(newPrice: currentPrice)
        }
        
        // Execute trade...
        transactionStatus = .completed
    }
}

struct AssetHolding: Identifiable {
    let id: String
    let symbol: String
    let name: String
    let quantity: Double
    let currentPrice: Double
    let purchasePrice: Double
    let type: AssetType
    
    var totalValue: Double { quantity * currentPrice }
    var profitLoss: Double { (currentPrice - purchasePrice) * quantity }
    var percentageChange: Double { ((currentPrice - purchasePrice) / purchasePrice) * 100 }
}

enum AssetType {
    case crypto
    case stock
}

extension TradingEnvironment {
    // Get combined holdings
    var holdings: [AssetHolding] {
        let cryptoHoldings = getCryptoHoldings()
        let stockHoldings = getStockHoldings()
        return cryptoHoldings + stockHoldings
    }
    
    private func getCryptoHoldings() -> [AssetHolding] {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        let trades = (try? coreDataStack.context.fetch(fetchRequest)) ?? []
        
        // Group trades by coinId
        let groupedTrades = Dictionary(grouping: trades) { $0.coinId ?? "" }
        
        return groupedTrades.compactMap { coinId, trades in
            // Calculate total quantity for this coin
            let totalQuantity = trades.reduce(0.0) { $0 + $1.quantity }
            
            // Only create holding if total quantity > 0
            guard totalQuantity > 0,
                  let firstTrade = trades.first else { return nil }
            
            let currentPrice = dataManager.coins.first { $0.id == coinId }?.current_price ?? firstTrade.currentPrice
            
            // Calculate weighted average purchase price
            let totalCost = trades.reduce(0.0) { $0 + (abs($1.quantity) * $1.purchasePrice) }
            let totalShares = trades.reduce(0.0) { $0 + abs($1.quantity) }
            let avgPurchasePrice = totalCost / totalShares
            
            return AssetHolding(
                id: coinId,
                symbol: firstTrade.coinSymbol ?? "",
                name: firstTrade.coinName ?? "",
                quantity: totalQuantity,
                currentPrice: currentPrice,
                purchasePrice: avgPurchasePrice,
                type: .crypto
            )
        }
    }

    private func getStockHoldings() -> [AssetHolding] {
        let fetchRequest: NSFetchRequest<StockTrade> = StockTrade.fetchRequest()
        let trades = (try? coreDataStack.context.fetch(fetchRequest)) ?? []
        
        // Group trades by symbol
        let groupedTrades = Dictionary(grouping: trades) { $0.symbol ?? "" }
        
        return groupedTrades.compactMap { symbol, trades in
            // Calculate total quantity for this stock
            let totalQuantity = trades.reduce(0.0) { $0 + $1.quantity }
            
            // Only create holding if total quantity > 0
            guard totalQuantity > 0,
                  let firstTrade = trades.first else { return nil }
            
            let currentPrice = dataManager.stocks.first { $0.symbol == symbol }?.quote.currentPrice ?? firstTrade.currentPrice
            
            // Calculate weighted average purchase price
            let totalCost = trades.reduce(0.0) { $0 + (abs($1.quantity) * $1.purchasePrice) }
            let totalShares = trades.reduce(0.0) { $0 + abs($1.quantity) }
            let avgPurchasePrice = totalCost / totalShares
            
            return AssetHolding(
                id: symbol,
                symbol: symbol,
                name: firstTrade.name ?? symbol,
                quantity: totalQuantity,
                currentPrice: currentPrice,
                purchasePrice: avgPurchasePrice,
                type: .stock
            )
        }
    }
}

// MARK: - Stock Trading
extension TradingEnvironment {
    func executeStockTrade(symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
        let totalCost = currentPrice * quantity
        
        guard let portfolio = currentPortfolio,
              portfolio.balance >= totalCost else {
            throw PaperTradingError.insufficientBalance
        }
        
        let trade = StockTrade(context: coreDataStack.context)
        trade.id = UUID()
        trade.symbol = symbol
        trade.name = name
        trade.quantity = quantity 
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.currentPrice = currentPrice
        trade.portfolio = portfolio
        
        portfolio.balance -= totalCost
        try coreDataStack.context.save()
    }
    
    func executeStockSell(symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
        let fetchRequest: NSFetchRequest<StockTrade> = StockTrade.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "symbol == %@", symbol)
        
        guard let trades = try? coreDataStack.context.fetch(fetchRequest),
              let portfolio = currentPortfolio else {
            throw PaperTradingError.generalError
        }
        
        let totalHoldings = trades.reduce(0.0) { $0 + $1.quantity }
        guard totalHoldings >= quantity else {
            throw PaperTradingError.insufficientHoldings
        }
        
        let trade = StockTrade(context: coreDataStack.context)
        trade.id = UUID()
        trade.symbol = symbol
        trade.name = name
        trade.quantity = -quantity
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.currentPrice = currentPrice
        trade.portfolio = portfolio
        
        let saleValue = currentPrice * quantity
        portfolio.balance += saleValue
        try coreDataStack.context.save()
    }
    
    // MARK: - Trade History Methods
    func fetchCryptoTrades() -> [CDTrade] {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDTrade.purchaseDate, ascending: false)]
        return (try? coreDataStack.context.fetch(fetchRequest)) ?? []
    }
    
    func fetchStockTrades() -> [StockTrade] {
        let fetchRequest: NSFetchRequest<StockTrade> = StockTrade.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \StockTrade.purchaseDate, ascending: false)]
        return (try? coreDataStack.context.fetch(fetchRequest)) ?? []
    }
}

// MARK: - Portfolio Reset
extension TradingEnvironment {
    func resetPortfolio() async throws {
        do {
            // Delete all trades
            let cryptoRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
            let stockRequest: NSFetchRequest<StockTrade> = StockTrade.fetchRequest()
            
            let cryptoTrades = try coreDataStack.context.fetch(cryptoRequest)
            let stockTrades = try coreDataStack.context.fetch(stockRequest)
            
            // Delete all trades
            cryptoTrades.forEach { coreDataStack.context.delete($0) }
            stockTrades.forEach { coreDataStack.context.delete($0) }
            
            // Reset portfolio balance
            currentPortfolio?.balance = 100_000
            
            try coreDataStack.context.save()
            objectWillChange.send()
        } catch {
            print("Error resetting portfolio: \(error)")
            throw error
        }
    }
}

enum TransactionStatus {
    case processing
    case completed
    case failed(Error)
    case priceChanged(newPrice: Double)
}