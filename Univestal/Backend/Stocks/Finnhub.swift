//
//  Finnhub.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/14/25.
//

import SwiftUI
// URL THAT WILL WORK FOR ALL STOCKS /search?q=apple&exchange=US, change apple to the search text var

/*
 Task {
 do {
 let stock = try await FinnhubAPI().fetchStock(symbol: "AAPL")
 print("Symbol: \(stock.symbol)")
 print("Current Price: \(stock.quote.close)")
 if let metrics = stock.metrics {
 print("52-Week High: \(metrics.fiftyTwoWeekHigh ?? 0)")
 }
 } catch {
 print("Error fetching stock: \(error)")
 }
 }
 */


@MainActor
class Finnhub: ObservableObject {
    static let shared = Finnhub()
    private let apiKey = Config.finnhubKey
    @Published var allStocks: [Stock] = []
    private let storage = Storage()
    
    // Fetch real-time stock quote
    func fetchStockQuote(symbol: String) async throws -> StockQuote {
        guard await APIRequestManager.shared.canMakeStockRequest() else {
            throw URLError(.networkConnectionLost)
        }
        
        guard let url = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(symbol)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        print("Response for \(symbol):")
        print(String(data: data, encoding: .utf8) ?? "No data")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(StockQuote.self, from: data)
    }
    
    // Fetch basic financial metrics, 52wk stats, etc.
    func fetchStockMetrics(symbol: String) async throws -> StockMetrics? {
        guard let url = URL(string: "https://finnhub.io/api/v1/stock/metric?symbol=\(symbol)&metric=all&token=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        print("Metrics response data for \(symbol):")
        print(String(data: data, encoding: .utf8) ?? "No data")
        
        let decoded = try JSONDecoder().decode(StockMetricsResponse.self, from: data)
        return decoded.metric
    }
    
    // For the textual data like description
    func lookupStock(query: String) async throws -> StockLookup? {
        guard let url = URL(string: "https://finnhub.io/api/v1/search?q=\(query)&exchange=US&token=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let lookupResponse = try JSONDecoder().decode(StockLookupResponse.self, from: data)
        
        print("Lookup response data for \(query):", lookupResponse)
        
        // Return the first result if available
        return lookupResponse.result.first
    }
    
    // Make a function that combines all endpoints into one.
    func fetchStocks(symbols: [String]) async throws -> [Stock] {
        var stocks: [Stock] = []
        let cache = StockCache.shared
        
        // Batch requests in groups of 25
        let batches = stride(from: 0, to: symbols.count, by: 25).map {
            Array(symbols[$0..<min($0 + 25, symbols.count)])
        }
        
        for batch in batches {
            APIRequestManager.shared.enqueueRequest(
                type: .stock,
                priority: .medium
            ) {
                for symbol in batch {
                    do {
                        let cachedMetadata = await cache.getCachedMetadata()[symbol]
                        async let quote = self.fetchStockQuote(symbol: symbol)
                        async let metrics = cachedMetadata?.metrics != nil ? 
                            cachedMetadata?.metrics : 
                            try await self.fetchStockMetrics(symbol: symbol)
                        async let lookup = cachedMetadata?.lookup != nil ? 
                            cachedMetadata?.lookup : 
                            try await self.lookupStock(query: symbol)
                        
                        let stock = try await Stock(symbol: symbol, quote: quote, metrics: metrics, lookup: lookup)
                        stocks.append(stock)
                        
                        try await cache.cacheMetadata(symbol: symbol, lookup: lookup, metrics: metrics)
                    } catch {
                        print("Error fetching stock data for \(symbol):", error)
                    }
                }
            }
        }
        
        return stocks
    }
    
    func fetchDefaultStocks() async {
        // Default symbols to load (25 common stocks)
        let symbols = storage.commonStocks
        
        await withTaskGroup(of: [Stock]?.self) { group in
                group.addTask {
                    do {
                        return try await self.fetchStocks(symbols: symbols)
                    } catch {
                        print("Failed to fetch stock for symbol: \(symbols)")
                        return nil
                    }
                }
            
            // Mapping the stock data fetched asynchronously to the array.
            var fetchedStocks: [Stock] = []
            for await stock in group {
                if let stock = stock {
                    fetchedStocks.append(contentsOf: stock)
                }
            }
            
            // Add on main thread
            DispatchQueue.main.async {
                self.allStocks = fetchedStocks
            }
        }
    }
    
    func testFetchDefaultStocks() async {
        do {
            // Test with just one stock first
            let stock = try await fetchStockQuote(symbol: "AAPL")
            print("Successfully fetched AAPL quote:", stock)
            
        } catch {
            print("Error fetching stocks:", error)
        }
    }
}
