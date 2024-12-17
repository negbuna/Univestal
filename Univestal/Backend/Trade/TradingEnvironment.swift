//
//  TradingEnvironment.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/16/24.
//

import SwiftUI
import CoreData

class TradingEnvironment: ObservableObject {
    static let shared = TradingEnvironment()
    
    @Published var crypto: Crypto
    @Published var currentPortfolio: CDPortfolio?
    private let coreDataStack: CoreDataStack
    
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
        guard let portfolio = currentPortfolio else {
            throw PaperTradingError.storageError("No portfolio found")
        }
        
        let totalCost = quantity * currentPrice
        guard portfolio.balance >= totalCost else {
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
}
