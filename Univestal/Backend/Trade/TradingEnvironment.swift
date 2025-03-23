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
    func executeTrade(coinId: String, symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
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
    
    func resetPortfolio() throws {
        let context = coreDataStack.context
        
        // Delete all trades
        let tradeRequest: NSFetchRequest<NSFetchRequestResult> = CDTrade.fetchRequest()
        let stockTradeRequest: NSFetchRequest<NSFetchRequestResult> = StockTrade.fetchRequest()
        
        let tradeBatchDelete = NSBatchDeleteRequest(fetchRequest: tradeRequest)
        let stockBatchDelete = NSBatchDeleteRequest(fetchRequest: stockTradeRequest)
        
        try context.execute(tradeBatchDelete)
        try context.execute(stockBatchDelete)
        
        // Reset portfolio balance
        if let portfolio = currentPortfolio {
            portfolio.balance = 100_000
            try context.save()
        }
        
        objectWillChange.send()
    }
    
    // Add dollar amount trading support
    func calculateQuantityFromAmount(dollars: Double, price: Double) -> Double {
        return dollars / price
    }
    
    func calculateAmountFromQuantity(quantity: Double, price: Double) -> Double {
        return quantity * price
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
        // Only fetch trades that have coinId (crypto trades)
        fetchRequest.predicate = NSPredicate(format: "coinId != nil")
        let trades = (try? coreDataStack.context.fetch(fetchRequest)) ?? []
        
        return trades.map { trade in
            let currentPrice = dataManager.coins.first { $0.id == trade.coinId }?.current_price ?? trade.currentPrice
            return AssetHolding(
                id: trade.coinId ?? UUID().uuidString,
                symbol: trade.coinSymbol ?? "",
                name: trade.coinName ?? "",
                quantity: trade.quantity,
                currentPrice: currentPrice,
                purchasePrice: trade.purchasePrice,
                type: .crypto
            )
        }
    }
    
    private func getStockHoldings() -> [AssetHolding] {
        let fetchRequest: NSFetchRequest<StockTrade> = StockTrade.fetchRequest()
        let trades = (try? coreDataStack.context.fetch(fetchRequest)) ?? []
        
        return trades.map { trade in
            let currentPrice = dataManager.stocks.first { $0.symbol == trade.symbol }?.quote.currentPrice ?? trade.currentPrice
            return AssetHolding(
                id: trade.symbol ?? UUID().uuidString,
                symbol: trade.symbol ?? "",
                name: trade.name ?? "",
                quantity: trade.quantity,
                currentPrice: currentPrice,
                purchasePrice: trade.purchasePrice,
                type: .stock
            )
        }
    }
}

// Add after struct AssetHolding and AssetType declarations
extension TradingEnvironment {
    // MARK: - Stock Trading
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
        let totalValue = currentPrice * quantity
        
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
        
        portfolio.balance += totalValue
        try coreDataStack.context.save()
    }
}

extension TradingEnvironment {
    // Public methods for fetching trades
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