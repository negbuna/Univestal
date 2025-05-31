//
//  AppData.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/14/24.
//

import Foundation
import CoreData
import SwiftUI

class AppData: ObservableObject {
    @Published var watchlist: Set<String> = [] // For coins
    @Published var stockWatchlist: Set<String> = []
    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        loadWatchlistFromCoreData()
    }
    
    // MARK: - Formatting Helpers
    
    func formatLargeNumber(_ number: Double) -> String {
        let absNumber = abs(number)
        switch absNumber {
        case 1_000_000_000_000...:
            return String(format: "$%.2fT", number / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "$%.2fB", number / 1_000_000_000)
        case 1_000_000...:
            return String(format: "$%.2fM", number / 1_000_000)
        case 1_000...:
            return String(format: "$%.0f", number)
        default:
            return String(format: "$%.2f", number)
        }
    }
    
    func formatPercentChange(_ number: Double) -> String {
        let sign = number >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", number))%"
    }
    
    func percentColor(_ number: Double) -> Color {
        if number > 0 {
            return .green
        } else if number < 0 {
            return .red
        } else {
            return .white
        }
    }
    
    // MARK: - Watchlist Management
    
    func loadWatchlistFromCoreData() {
        let request = NSFetchRequest<WatchlistItem>(entityName: "WatchlistItem")
        let stockRequest = NSFetchRequest<StockWatchlistItem>(entityName: "StockWatchlistItem")
        
        do {
            let items = try viewContext.fetch(request)
            let stockItems = try viewContext.fetch(stockRequest)
            watchlist = Set(items.compactMap { $0.coinId })
            stockWatchlist = Set(stockItems.compactMap { $0.stockSymbol })
            print("Loaded stock watchlist: \(stockWatchlist)")
        } catch {
            print("Error loading watchlists: \(error)")
        }
    }

    func toggleWatchlist(for coinId: String) {
        if watchlist.contains(coinId) {
            removeFromWatchlist(coinId)
        } else {
            addToWatchlist(coinId)
        }
        objectWillChange.send()
    }
    
    func toggleStockWatchlist(for symbol: String) {
        if stockWatchlist.contains(symbol) {
            removeFromStockWatchlist(symbol)
        } else {
            addToStockWatchlist(symbol)
        }
        objectWillChange.send()
    }
    
    private func addToWatchlist(_ coinId: String) {
        let item = NSEntityDescription.insertNewObject(forEntityName: "WatchlistItem", 
                                                    into: viewContext) as! WatchlistItem
        item.coinId = coinId
        item.dateAdded = Date()
        
        do {
            try viewContext.save()
            watchlist.insert(coinId)
        } catch {
            print("Error adding to watchlist: \(error)")
        }
    }
    
    private func removeFromWatchlist(_ coinId: String) {
        let request = NSFetchRequest<WatchlistItem>(entityName: "WatchlistItem")
        request.predicate = NSPredicate(format: "coinId == %@", coinId)
        
        do {
            let items = try viewContext.fetch(request)
            items.forEach { viewContext.delete($0) }
            try viewContext.save()
            watchlist.remove(coinId)
        } catch {
            print("Error removing from watchlist: \(error)")
        }
    }
    
    private func addToStockWatchlist(_ symbol: String) {
        let item = NSEntityDescription.insertNewObject(forEntityName: "StockWatchlistItem", 
                                                    into: viewContext) as! StockWatchlistItem
        item.stockSymbol = symbol
        item.dateAdded = Date()
        
        do {
            try viewContext.save()
            stockWatchlist.insert(symbol)
        } catch {
            print("Error adding to stock watchlist: \(error)")
        }
    }
    
    private func removeFromStockWatchlist(_ symbol: String) {
        let request = NSFetchRequest<StockWatchlistItem>(entityName: "StockWatchlistItem")
        request.predicate = NSPredicate(format: "stockSymbol == %@", symbol)
        
        do {
            let items = try viewContext.fetch(request)
            items.forEach { viewContext.delete($0) }
            try viewContext.save()
            stockWatchlist.remove(symbol)
        } catch {
            print("Error removing from stock watchlist: \(error)")
        }
    }
}

// App colors
struct ColorManager {
    static var bkgColor: Color = Color(UIColor.systemBackground)
}
