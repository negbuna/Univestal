//
//  StockModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/26/25.
//

import Foundation

// Models to represent the JSON response
struct Stock: Codable, Identifiable, Hashable {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let percentChange: Double
    
    var id: String { symbol }
}

struct PolygonResponse: Codable {
    let status: String
    let request_id: String
    let error: String?
    let results: [StockData]?
    let ticker: String?
    
    // Make consolidated response fields
    enum CodingKeys: String, CodingKey {
        case status
        case request_id
        case error
        case results
        case ticker
    }
}

struct StockQuote: Codable {
    let close: Double
    let change: Double
    let percentChange: Double
    let name: String?
    
    // Latest quote fields
    enum CodingKeys: String, CodingKey {
        case close = "c"
        case change = "d"
        case percentChange = "dp"
        case name
    }
}

struct StockData: Codable {
    let c: Double // close price
    let h: Double // highest price
    let l: Double // lowest price
    let n: Int    // number of transactions
    let o: Double // open price
    let t: Int    // Unix msec timestamp
    let v: Int    // trading volume
}

struct PolygonBar: Identifiable {
    let id = UUID()
    let close: Double
    let high: Double
    let low: Double
    let open: Double
    let timestamp: Int // Keep as Int for Unix timestamp
    let volume: Int
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }
}

struct StockSymbols {
    static let commonStocks = [
        // Technology
        "AAPL", "MSFT", "GOOGL", "META", "AMZN", "NVDA", "TSLA", "AMD", "INTC", "CRM",
        // Financial
        "JPM", "BAC", "WFC", "GS", "MS", "V", "MA", "AXP",
        // Healthcare
        "JNJ", "PFE", "UNH", "ABBV", "MRK", "CVS",
        // Consumer
        "KO", "PEP", "WMT", "TGT", "SBUX", "MCD", "NKE",
        // Industrial
        "BA", "CAT", "GE", "MMM", "HON",
        // Energy
        "XOM", "CVX", "COP", "BP", "SHELL",
        // Communication
        "VZ", "T", "TMUS", "CMCSA", "DIS",
        // Retail
        "COST", "HD", "LOW", "TJX"
    ]
}
