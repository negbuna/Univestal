//
//  TradeModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/9/24.
//

import Foundation
import CoreData
import SwiftUI

struct Trade {
    let id: UUID
    let coinId: String
    let coinSymbol: String
    let coinName: String
    let quantity: Double
    let purchasePrice: Double
    let purchaseDate: Date
    var currentPrice: Double?
    
    var currentValue: Double {
        return (currentPrice ?? purchasePrice) * quantity
    }
    
    var profitLoss: Double {
        guard let currentPrice = currentPrice else { return 0 }
        return (currentPrice - purchasePrice) * quantity
    }
    
    var profitLossPercentage: Double {
        guard let currentPrice = currentPrice else { return 0 }
        return ((currentPrice - purchasePrice) / purchasePrice) * 100
    }
}

struct Portfolio {
    var balance: Double
    var trades: [Trade]
    
    var totalInvestment: Double {
        trades.reduce(0) { $0 + ($1.purchasePrice * $1.quantity) }
    }
    
    var currentPortfolioValue: Double {
        trades.reduce(0) { $0 + ($1.currentPrice ?? $1.purchasePrice * $1.quantity) }
    }
    
    var totalProfitLoss: Double {
        trades.reduce(0) { $0 + $1.profitLoss }
    }
    
    mutating func addTrade(_ trade: Trade) {
        trades.append(trade)
    }
    
    mutating func removeTrade(_ trade: Trade) {
        trades.removeAll { $0.id == trade.id }
    }
}

enum TransactionType {
    case buy
    case sell
}

struct Transaction {
    let id: UUID
    let trade: Trade
    let type: TransactionType
    let timestamp: Date
    let totalCost: Double
}

class PaperTradingSimulator: ObservableObject {
    private let coreDataStack: CoreDataStack
    
    init(initialBalance: Double) {
        self.coreDataStack = CoreDataStack.shared
        
        // Check if portfolio exists, if not create a new one
        if !portfolioExists() {
            createInitialPortfolio(initialBalance: initialBalance)
        }
    }
    
    private func portfolioExists() -> Bool {
        let fetchRequest = NSFetchRequest<CDPortfolio>(entityName: "CDPortfolio")

        do {
            let count = try coreDataStack.context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking portfolio existence: \(error)")
            return false
        }
    }
    
    private func createInitialPortfolio(initialBalance: Double) {
        let portfolio = CDPortfolio(context: coreDataStack.context)
        portfolio.balance = initialBalance
        portfolio.trades = NSMutableSet()
        
        coreDataStack.saveContext()
    }
    
    func getCurrentPortfolio() throws -> CDPortfolio {
        let fetchRequest = NSFetchRequest<CDPortfolio>(entityName: "CDPortfolio")

        do {
            let portfolios = try coreDataStack.context.fetch(fetchRequest)
            guard let portfolio = portfolios.first else {
                throw PaperTradingError.storageError("No portfolio found")
            }
            return portfolio
        } catch {
            throw PaperTradingError.storageError("Failed to retrieve portfolio: \(error.localizedDescription)")
        }
    }
    
    func buyCoin(coinId: String, symbol: String, name: String, quantity: Double, currentPrice: Double) throws -> CDTrade {
        guard quantity > 0 else {
            throw PaperTradingError.invalidQuantity
        }
        
        let portfolio = try getCurrentPortfolio()
        let totalCost = quantity * currentPrice
        
        guard portfolio.balance >= totalCost else {
            throw PaperTradingError.insufficientBalance
        }
        
        // Create new trade
        let trade = CDTrade(context: coreDataStack.context)
        trade.id = UUID()
        trade.coinId = coinId
        trade.coinSymbol = symbol
        trade.coinName = name
        trade.quantity = quantity
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.currentPrice = currentPrice
        
        // Update portfolio balance
        portfolio.balance -= totalCost
        
        // Add trade to portfolio
        guard var trades = portfolio.trades as? NSMutableSet else {
            throw PaperTradingError.storageError("Failed to get trades from portfolio")
        }
        let mutableTrades = trades.mutableCopy() as! NSMutableSet
        mutableTrades.add(trade)
        trades = mutableTrades
        
        // Save context
        coreDataStack.saveContext()
        
        return trade
    }
    
    func sellCoin(tradeId: UUID, currentPrice: Double) throws {
        let fetchRequest = NSFetchRequest<CDTrade>(entityName: "CDTrade")
        fetchRequest.predicate = NSPredicate(format: "id == %@", tradeId as CVarArg)
        
        do {
            let trades = try coreDataStack.context.fetch(fetchRequest)
            guard let trade = trades.first else {
                throw PaperTradingError.tradeNotFound
            }
            
            let portfolio = try getCurrentPortfolio()
            let saleValue = trade.quantity * currentPrice
            
            // Update portfolio balance
            portfolio.balance += saleValue
            
            // Remove trade from portfolio
            guard let trades = portfolio.trades else {
                print("Trades set is nil")
                return
            }
            let mutableTrades = trades.mutableCopy() as! NSMutableSet // Don't need to downcast here
            mutableTrades.remove(trade)
            portfolio.trades = mutableTrades
            
            // Delete the trade
            coreDataStack.context.delete(trade)
            
            // Save changes
            coreDataStack.saveContext()
        } catch {
            throw PaperTradingError.storageError("Failed to sell coin: \(error.localizedDescription)")
        }
    }
    
    func updateTradesPrices(prices: [String: Double]) throws {
        let fetchRequest = NSFetchRequest<CDTrade>(entityName: "CDTrade")

        do {
            let trades = try coreDataStack.context.fetch(fetchRequest)
            
            for trade in trades {
                if let coinId = trade.coinId, let currentPrice = prices[coinId] {
                    trade.currentPrice = currentPrice
                }
            }
            
            coreDataStack.saveContext()
        } catch {
            throw PaperTradingError.storageError("Failed to update trade prices: \(error.localizedDescription)")
        }
    }
    
    func getPortfolioValue() throws -> (balance: Double, totalValue: Double) {
        let portfolio = try getCurrentPortfolio()
        guard let trades = portfolio.trades as? Set<CDTrade> else {
            throw PaperTradingError.storageError("Failed to get trades from portfolio")
        }
        
        var _ = Array(trades)
        
        let totalTradeValue = trades.reduce(0.0) { total, trade in
            return total + (trade.currentPrice * trade.quantity)
        }
        
        return (balance: portfolio.balance, totalValue: portfolio.balance + totalTradeValue)
    }
}

// Usage Example
class PaperTradingManager: ObservableObject {
    @ObservedObject var crypto: Crypto
    @ObservedObject var simulator: PaperTradingSimulator
    @Published var tradedCoin: String = ""
    @Published var tradedQuantity: String = ""
    @Published var portfolioValue: (balance: Double, totalValue: Double) = (0, 0)
    
    init(crypto: Crypto, simulator: PaperTradingSimulator) {
        self.crypto = crypto
        self.simulator = simulator
        
        do {
            let portfolio = try simulator.getCurrentPortfolio()
            self.portfolioValue = (balance: portfolio.balance, totalValue: portfolio.balance)
        } catch {
            print("Error initializing portfolio value: \(error)")
            self.portfolioValue = (balance: 0, totalValue: 0) // Fallback if retrieval fails
        }
        
        setupCoinPriceUpdates()
    }
    
    func updatePortfolioValue() {
        do {
            portfolioValue = try simulator.getPortfolioValue()
        } catch {
            print("Error getting portfolio value: \(error)")
            portfolioValue = (0, 0)
        }
    }
    
    private func setupCoinPriceUpdates() {
        crypto.$coins
            .sink { [weak self] coins in
                self?.updateTradesPrices(coins: coins)
            }
            .store(in: &crypto.cancellables)
    }
    
    private func updateTradesPrices(coins: [Coin]) {
        // Create a dictionary of coin prices
        let coinPrices = Dictionary(uniqueKeysWithValues: coins.map { ($0.id, $0.current_price) })
        
        do {
            try simulator.updateTradesPrices(prices: coinPrices)
        } catch {
            print("Error updating trade prices: \(error)")
        }
    }
    
    func performAutomaticTrade(coinId: String) {
        // Find the coin from the fetched list
        guard let coin = crypto.coins.first(where: { $0.id == coinId }) else {
            print("Coin not found")
            return
        }
        
        do {
            // Example trading logic - you can make this more sophisticated
            let quantity = 0.1 // Example fixed quantity
            
            // Buy the coin
            let trade = try simulator.buyCoin(
                coinId: coin.id,
                symbol: coin.symbol,
                name: coin.name,
                quantity: quantity,
                currentPrice: coin.current_price
            )
            
            print("Bought \(quantity) \(coin.name) at \(coin.current_price)")
            
            // Optional: Implement sell logic
            // For example, sell if price increases by 5%
            let sellThreshold = trade.purchasePrice * 1.05
            if coin.current_price >= sellThreshold {
                if let id = trade.id {
                    try simulator.sellCoin(tradeId: id, currentPrice: coin.current_price)
                    print("Sold \(coin.name) at \(coin.current_price)")
                } else {
                    print()
                    print("Error: UUID returned nil")
                }
            }
        } catch let error as PaperTradingError {
            print("Trading Error: \(error.localizedDescription)")
        } catch {
            print("Unexpected Error: \(error)")
        }
    }
    
    // Method to start fetching coin prices
    func startTradingSimulation() {
        crypto.fetchCoins()
    }
}
