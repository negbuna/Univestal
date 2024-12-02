//
//  AlpacaModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import Foundation
import Combine
// Might not use this

struct Stock: Hashable, Codable { // Attributes for a Stock
    let symbol: String
    let price: Double
}

struct Account: Hashable, Codable { // Attributes for an Account
    let id: String
    let cash: String
    let portfolioValue: String
}

struct Order: Hashable, Codable { // Attributes for an order
    let id: String
    let symbol: String
    let qty: Int
    let filledQty: Int
    let status: String
}

class AlpacaModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var account: Account?
    @Published var orders: [Order] = []
    
    func fetchStocks() {
        guard let url = URL(string: "https://paper-api.alpaca.markets/v2/stocks") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Failed to fetch stocks: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON Response: \(jsonString)")
            }

            
            // Converting to JSON
            do {
                let stocks = try JSONDecoder().decode([Stock].self, from: data)
                DispatchQueue.main.async {
                    self?.stocks = stocks
                    print("Fetched stocks: \(stocks)")
                }
            } catch {
                print("Failed to decode stocks: \(error)")
            }
        }
        task.resume()
    }
    
    func fetchAccount() {
        guard let url = URL(string: "https://paper-api.alpaca.markets/v2/account") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Failed to fetch account: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Converting to JSON
            do {
                let account = try JSONDecoder().decode(Account.self, from: data)
                DispatchQueue.main.async {
                    self?.account = account
                    print("Fetched account: \(account)")
                }
            } catch {
                print("Failed to decode account: \(error)")
            }
        }
        task.resume()
    }
    
    func fetchOrders() {
        guard let url = URL(string: "https://paper-api.alpaca.markets/v2/orders") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Failed to fetch orders: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Converting to JSON
            do {
                let orders = try JSONDecoder().decode([Order].self, from: data)
                DispatchQueue.main.async {
                    self?.orders = orders
                    print("Fetched orders: \(orders)")
                }
            } catch {
                print("Failed to decode orders: \(error)")
            }
        }
        task.resume()
    }
}
