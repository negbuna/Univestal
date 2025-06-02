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
    let crypto = Crypto.shared
    
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
        let holdings = holdings.reduce(0.0) { $0 + $1.totalValue }
        return portfolioBalance + holdings
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
        objectWillChange.send()
    }
    
    func executeSell(coinId: String, symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
        // Get current holdings for this coin
        let holdings = getCurrentHoldingsForCoin(coinId: coinId)
        
        // Check if we have enough (use a small epsilon for floating point comparison)
        let epsilon = 0.000001
        guard holdings >= (quantity - epsilon) else {
            throw PaperTradingError.insufficientHoldings
        }
        
        guard let portfolio = currentPortfolio else {
            throw PaperTradingError.generalError
        }
        
        let trade = CDTrade(context: coreDataStack.context)
        trade.id = UUID()
        trade.coinId = coinId
        trade.coinSymbol = symbol
        trade.coinName = name
        trade.quantity = -quantity  // Negative for sells
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.currentPrice = currentPrice
        trade.portfolio = portfolio
        
        portfolio.balance += (currentPrice * quantity)
        try coreDataStack.context.save()
        objectWillChange.send()
    }

    // Helper method to get total holdings for a coin
    private func getCurrentHoldingsForCoin(coinId: String) -> Double {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "coinId == %@", coinId)
        
        guard let trades = try? coreDataStack.context.fetch(fetchRequest) else {
            return 0
        }
        
        return trades.reduce(0.0) { total, trade in
            total + trade.quantity
        }
    }

    // Simple 24h portfolio change calculation
    func portfolioChange() -> (amount: Double, percentage: Double)? {
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
            objectWillChange.send()  // <-- Explicitly notify observers
        }
    }
    
    func fetchCryptoData() async {
        let crypto = Crypto.shared
        do {
            let response = try await crypto.fetchMarketData(page: 1)
            await MainActor.run {
                self.coins = response.items
                objectWillChange.send()  // <-- Explicitly notify observers
            }
        } catch {
            print("Error fetching crypto data: \(error)")
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
        
        // 1. Delete all trades
        let tradeRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDTrade")
        let stockTradeRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "StockTrade")
        let portfolioRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPortfolio")
        
        let deletes = [
            NSBatchDeleteRequest(fetchRequest: tradeRequest),
            NSBatchDeleteRequest(fetchRequest: stockTradeRequest),
            NSBatchDeleteRequest(fetchRequest: portfolioRequest)
        ]
        
        // Execute batch deletes
        try deletes.forEach { try context.execute($0) }
        
        // 2. Reset in-memory state (remove the direct holdings assignment)
        self.currentPortfolio = nil
        
        // 3. Create new portfolio
        let newPortfolio = CDPortfolio(context: context)
        newPortfolio.balance = 100_000
        try context.save()
        
        // 4. Update current portfolio reference
        self.currentPortfolio = newPortfolio
        
        // 5. Notify observers
        objectWillChange.send()
        
        // Refresh market data (optional)
        Task {
            await fetchCryptoData()
            try? await fetchStockData() 
        }
    }
    
    // Add dollar amount trading support
    func calculateQuantityFromAmount(dollars: Double, price: Double) -> Double {
        return dollars / price
    }
    
    func calculateAmountFromQuantity(quantity: Double, price: Double) -> Double {
        return quantity * price
    }
    
    // Add this method to support crypto search with pagination
    func searchCoins(query: String, page: Int) async throws -> PaginatedResponse<Coin> {
        return try await crypto.searchCoins(query: query, page: page)
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
        let context = coreDataStack.context
        
        // Fetch both types of trades
        let stockRequest: NSFetchRequest<StockTrade> = StockTrade.fetchRequest()
        let cryptoRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        
        let stockTrades = (try? context.fetch(stockRequest)) ?? []
        let cryptoTrades = (try? context.fetch(cryptoRequest)) ?? []
        
        // Convert to holdings
        let stockHoldings = stockTrades.map { trade in
            AssetHolding(
                id: trade.symbol ?? "",
                symbol: trade.symbol ?? "",
                name: trade.name ?? "",
                quantity: trade.quantity,
                currentPrice: stocks.first { $0.symbol == trade.symbol }?.quote.currentPrice ?? trade.purchasePrice,
                purchasePrice: trade.purchasePrice,
                type: .stock
            )
        }
        
        let cryptoHoldings = cryptoTrades.map { trade in
            AssetHolding(
                id: trade.coinId ?? "",
                symbol: trade.coinSymbol ?? "",
                name: trade.coinName ?? "",
                quantity: trade.quantity,
                currentPrice: coins.first { $0.id == trade.coinId }?.current_price ?? trade.purchasePrice,
                purchasePrice: trade.purchasePrice,
                type: .crypto
            )
        }
        
        return stockHoldings + cryptoHoldings
    }
    
    private func getCryptoHoldings() -> [AssetHolding] {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "coinId != nil"),
            NSPredicate(format: "coinId != ''")
        ])
        
        let trades = (try? coreDataStack.context.fetch(fetchRequest)) ?? []
        print("DEBUG: Found \(trades.count) crypto trades")
        
        return trades.compactMap { trade in
            guard let coinId = trade.coinId,
                  !coinId.isEmpty else { return nil }
            
            let currentPrice = dataManager.coins.first { $0.id == coinId }?.current_price ?? trade.currentPrice
            
            return AssetHolding(
                id: coinId,
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
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "symbol != nil"),
            NSPredicate(format: "symbol != ''")
        ])
        
        let trades = (try? coreDataStack.context.fetch(fetchRequest)) ?? []
        print("DEBUG: Found \(trades.count) stock trades")
        
        let holdings = trades.map { trade -> AssetHolding in
            let symbol = trade.symbol ?? ""
            let currentPrice = dataManager.stocks.first { $0.symbol == symbol }?.quote.currentPrice ?? trade.currentPrice
            
            return AssetHolding(
                id: symbol,
                symbol: symbol,
                name: trade.name ?? "",
                quantity: trade.quantity,
                currentPrice: currentPrice,
                purchasePrice: trade.purchasePrice,
                type: .stock
            )
        }
        
        // Group holdings by symbol and combine quantities
        return Dictionary(grouping: holdings, by: { $0.symbol })
            .values
            .map { holdings in
                let totalQuantity = holdings.reduce(0) { $0 + $1.quantity }
                let first = holdings[0]
                return AssetHolding(
                    id: first.id,
                    symbol: first.symbol,
                    name: first.name,
                    quantity: totalQuantity,
                    currentPrice: first.currentPrice,
                    purchasePrice: first.purchasePrice,
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

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
