//
//  Environment.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/16/24.
//

import SwiftUI
import CoreData
import Combine
import Foundation

class TradingEnvironment: ObservableObject {
    static let shared = TradingEnvironment()
    
    @Published var crypto: Crypto
    @Published var currentPortfolio: CDPortfolio?
    let coreDataStack: CoreDataStack
    
    // Computed property for holdings value
    var holdingsValue: Double? {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        guard let trades = try? coreDataStack.context.fetch(fetchRequest) else {
            return nil
        }
        
        let value = trades.reduce(0.0) { total, trade in
            let currentPrice = crypto.coins.first { $0.id == trade.coinId }?.current_price ?? trade.purchasePrice
            return total + (currentPrice * trade.quantity)
        }
        
        return value
    }
    
    // Total portfolio value using optional
    var totalPortfolioValue: Double {
        return portfolioBalance + (holdingsValue ?? 0.0)
    }
    
    private init() {
        self.crypto = Crypto()
        self.coreDataStack = CoreDataStack.shared
        
        // Initialize or fetch existing portfolio
        setupPortfolio()
    }
    
    private func setupPortfolio() {
        let fetchRequest: NSFetchRequest<CDPortfolio> = CDPortfolio.fetchRequest()
        
        do {
            let portfolios = try coreDataStack.context.fetch(fetchRequest)
            if let existingPortfolio = portfolios.first {
                self.currentPortfolio = existingPortfolio
            } else {
                // Create new portfolio if none exists
                let newPortfolio = CDPortfolio(context: coreDataStack.context)
                newPortfolio.balance = 100_000 // Initial balance
                try coreDataStack.context.save()
                self.currentPortfolio = newPortfolio
            }
        } catch {
            print("Error setting up portfolio: \(error)")
        }
    }
    
    // Helper computed properties
    var portfolioBalance: Double {
        currentPortfolio?.balance ?? 0.0
    }
    
    var trades: [CDTrade] {
        (currentPortfolio?.trades?.allObjects as? [CDTrade]) ?? []
    }
    
    // MARK: - Trading Functions
    func executeTrade(coinId: String, symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
        let totalCost = currentPrice * quantity
        
        guard let portfolio = currentPortfolio,
              portfolio.balance >= totalCost else {
            throw PaperTradingError.insufficientBalance
        }
        
        let context = coreDataStack.context
        let trade = CDTrade(context: context)
        trade.id = UUID()
        trade.coinId = coinId
        trade.coinSymbol = symbol
        trade.coinName = name
        trade.quantity = quantity
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.portfolio = portfolio
        
        portfolio.balance -= totalCost
        
        do {
            try context.save()
            print("Trade saved successfully: \(quantity) \(symbol) at $\(currentPrice)")
        } catch {
            context.rollback()
            print("Failed to save trade: \(error)")
            throw error
        }
    }
    
    func executeSell(coinId: String, symbol: String, name: String, quantity: Double, currentPrice: Double) throws {
        let totalValue = currentPrice * quantity
        
        // Check if user has enough of the coin to sell
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "coinId == %@", coinId)
        
        guard let trades = try? coreDataStack.context.fetch(fetchRequest) else {
            throw PaperTradingError.generalError
        }
        
        let totalHoldings = trades.reduce(0.0) { $0 + $1.quantity }
        
        guard totalHoldings >= quantity else {
            throw PaperTradingError.insufficientHoldings
        }
        
        guard let portfolio = currentPortfolio else {
            throw PaperTradingError.generalError
        }
        
        // Create a sell trade (negative quantity)
        let trade = CDTrade(context: coreDataStack.context)
        trade.id = UUID()
        trade.coinId = coinId
        trade.coinSymbol = symbol
        trade.coinName = name
        trade.quantity = -quantity  // Negative for sells
        trade.purchasePrice = currentPrice
        trade.purchaseDate = Date()
        trade.portfolio = portfolio
        
        portfolio.balance += totalValue
        
        do {
            try coreDataStack.context.save()
        } catch {
            coreDataStack.context.rollback()
            throw error
        }
    }
    
    func updatePrices(with prices: [String: Double]) {
        trades.forEach { trade in
            if let coinId = trade.coinId,
               let currentPrice = prices[coinId] {
                trade.currentPrice = currentPrice
            }
        }
        
        try? coreDataStack.context.save()
        objectWillChange.send()
    }
    
    func portfolioChange(for timeFrame: TimeFrame) -> (amount: Double, percentage: Double)? {
        let fetchRequest: NSFetchRequest<CDTrade> = CDTrade.fetchRequest()
        guard let trades = try? coreDataStack.context.fetch(fetchRequest) else { return nil }
        
        var totalChange = 0.0
        var totalValue = 0.0
        
        let holdingsByCoin = Dictionary(grouping: trades, by: { $0.coinId })
        
        for (coinId, trades) in holdingsByCoin {
            let quantity = trades.reduce(0.0) { $0 + $1.quantity }
            
            guard quantity != 0,
                  let coin = crypto.coins.first(where: { $0.id == coinId }) else {
                continue
            }
            
            // Get price change based on timeframe
            let priceChange: Double? = {
                switch timeFrame {
                case .day:
                    return coin.price_change_24h
                case .week:
                    guard let sparkline = coin.sparkline_in_7d?.price,
                          sparkline.count > 0 else { return nil }
                    return coin.current_price - sparkline[0]
                }
            }()
            
            guard let change = priceChange else { continue }
            
            let valueChange = change * quantity
            totalChange += valueChange
            
            // Calculate current value for percentage calculation
            totalValue += coin.current_price * quantity
        } 
        
        let percentageChange = totalValue > 0 ? (totalChange / totalValue) * 100 : 0
        return (totalChange, percentageChange)
    }
}
