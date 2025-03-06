//
//  FinnhubModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/18/25.
//

import Foundation

struct Stock: Codable {
    let symbol: String
    let quote: StockQuote
    let metrics: StockMetrics?
    let lookup: StockLookup?
}

// https://finnhub.io/api/v1/quote?symbol=(symbol)&token=(Config.finnhubKey)

struct StockQuote: Codable {
    let currentPrice: Double
    let change: Double?
    let percentChange: Double?
    let highPrice: Double
    let lowPrice: Double
    let openPrice: Double
    let previousClose: Double
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case currentPrice = "c"
        case change = "d"
        case percentChange = "dp"
        case highPrice = "h"
        case lowPrice = "l"
        case openPrice = "o"
        case previousClose = "pc"
        case timestamp = "t"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        change = try container.decodeIfPresent(Double.self, forKey: .change)
        percentChange = try container.decodeIfPresent(Double.self, forKey: .percentChange)
        highPrice = try container.decode(Double.self, forKey: .highPrice)
        lowPrice = try container.decode(Double.self, forKey: .lowPrice)
        openPrice = try container.decode(Double.self, forKey: .openPrice)
        previousClose = try container.decode(Double.self, forKey: .previousClose)
        
        let timestampInt = try container.decode(Int.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
    }
}

struct StockMetrics: Codable {
    let beta: Double?
    let fiftyTwoWeekHigh: Double?
    let fiftyTwoWeekLow: Double?
    let currentRatio: Double?
    let salesPerShare: Double?
    let netMargin: Double?
    
    enum CodingKeys: String, CodingKey {
        case beta
        case fiftyTwoWeekHigh = "52WeekHigh"
        case fiftyTwoWeekLow = "52WeekLow"
        case currentRatio, salesPerShare, netMargin
    }
}

struct StockMetricsResponse: Codable {
    let metric: StockMetrics
}

struct MetricValue: Codable {
    let period: String
    let value: Double
    
    enum CodingKeys: String, CodingKey {
        case period
        case value = "v"
    }
}

struct StockLookupResponse: Codable {
    let count: Int
    let result: [StockLookup]
}

struct StockLookup: Codable, Identifiable {
    let symbol: String
    let displaySymbol: String
    let description: String
    let type: String
    
    var id: String { symbol }
}

struct Storage {
    let commonStocks = [
        // Technology
        "AAPL",  // Apple
        "MSFT",  // Microsoft
        "GOOGL", // Alphabet (Google)
        "AMZN",  // Amazon
        "META",  // Meta Platforms (Facebook)
        
        // Finance
        "JPM",   // JPMorgan Chase
        "BAC",   // Bank of America
        "WFC",   // Wells Fargo
        "C",     // Citigroup
        "GS",    // Goldman Sachs
        
        // Healthcare
        "JNJ",   // Johnson & Johnson
        "PFE",   // Pfizer
        "MRK",   // Merck & Co.
        "UNH",   // UnitedHealth Group
        "ABBV",  // AbbVie
        
        // Consumer Goods
        "PG",    // Procter & Gamble
        "KO",    // Coca-Cola
        "PEP",   // PepsiCo
        "NKE",   // Nike
        "MCD",   // McDonald's
        
        // Energy
        "XOM",   // Exxon Mobil
        "CVX",   // Chevron
        "COP",   // ConocoPhillips
        "SLB",   // Schlumberger
        "EOG"    // EOG Resources
    ]
}

extension Stock {
    static let mockStocks: [Stock] = [
        Stock(
            symbol: "AAPL",
            quote: try! JSONDecoder().decode(StockQuote.self, from: """
                {
                    "c": 178.50,
                    "d": 2.30,
                    "dp": 1.32,
                    "h": 180.00,
                    "l": 176.20,
                    "o": 177.00,
                    "pc": 176.20,
                    "t": \(Int(Date().timeIntervalSince1970))
                }
                """.data(using: .utf8)!),
            metrics: StockMetrics(
                beta: 1.2,
                fiftyTwoWeekHigh: 190.00,
                fiftyTwoWeekLow: 140.00,
                currentRatio: 1.5,
                salesPerShare: 10.5,
                netMargin: 20.0
            ),
            lookup: StockLookup(
                symbol: "AAPL",
                displaySymbol: "AAPL",
                description: "Apple Inc.",
                type: "Common Stock"
            )
        ),
        Stock(
            symbol: "MSFT",
            quote: try! JSONDecoder().decode(StockQuote.self, from: """
                {
                    "c": 402.15,
                    "d": -1.85,
                    "dp": -0.46,
                    "h": 405.00,
                    "l": 400.00,
                    "o": 404.00,
                    "pc": 404.00,
                    "t": \(Int(Date().timeIntervalSince1970))
                }
                """.data(using: .utf8)!),
            metrics: StockMetrics(
                beta: 0.9,
                fiftyTwoWeekHigh: 410.00,
                fiftyTwoWeekLow: 300.00,
                currentRatio: 2.1,
                salesPerShare: 15.3,
                netMargin: 18.0
            ),
            lookup: StockLookup(
                symbol: "MSFT",
                displaySymbol: "MSFT",
                description: "Microsoft Corporation",
                type: "Common Stock"
            )
        ),
        Stock(
            symbol: "GOOGL",
            quote: try! JSONDecoder().decode(StockQuote.self, from: """
                {
                    "c": 141.80,
                    "d": 0.75,
                    "dp": 0.53,
                    "h": 142.50,
                    "l": 140.90,
                    "o": 141.00,
                    "pc": 141.05,
                    "t": \(Int(Date().timeIntervalSince1970))
                }
                """.data(using: .utf8)!),
            metrics: StockMetrics(
                beta: 1.1,
                fiftyTwoWeekHigh: 150.00,
                fiftyTwoWeekLow: 120.00,
                currentRatio: 2.0,
                salesPerShare: 12.8,
                netMargin: 25.5
            ),
            lookup: StockLookup(
                symbol: "GOOGL",
                displaySymbol: "GOOGL",
                description: "Alphabet Inc.",
                type: "Common Stock"
            )
        )
    ]
}
