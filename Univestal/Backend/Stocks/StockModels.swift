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
    let close: Double
    let high: Double
    let low: Double
    let transactions: Int
    let open: Double
    let timestamp: Int
    let volume: Int
    let volumeWeightedAverage: Double

    enum CodingKeys: String, CodingKey {
        case close = "c"
        case high = "h"
        case low = "l"
        case transactions = "n"
        case open = "o"
        case timestamp = "t"
        case volume = "v"
        case volumeWeightedAverage = "vw"
    }
}

struct PolygonBar: Codable, Identifiable {
    let c: Double // close
    let h: Double // high
    let l: Double // low
    let o: Double // open
    let t: Int    // timestamp
    let v: Int    // volume
    
    var id: Int { t }
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