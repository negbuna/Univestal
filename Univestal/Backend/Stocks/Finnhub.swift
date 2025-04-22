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

enum FinnhubEndpoint {
    struct Quote: APIEndpoint {
        typealias Response = StockQuote
        let symbol: String
        
        var baseURL: String { "https://finnhub.io/api/v1" }
        var path: String { "/quote" }
        var queryItems: [URLQueryItem] {
            [
                .init(name: "symbol", value: symbol),
                .init(name: "token", value: Config.finnhubKey)
            ]
        }
        var resourceType: APIResourceType { .stockQuote }
        var cacheKey: String { "quote_\(symbol)" }
    }
    
    struct Metrics: APIEndpoint {
        typealias Response = StockMetricsResponse
        let symbol: String
        
        var baseURL: String { "https://finnhub.io/api/v1" }
        var path: String { "/stock/metric" }
        var queryItems: [URLQueryItem] {
            [
                .init(name: "symbol", value: symbol),
                .init(name: "metric", value: "all"),
                .init(name: "token", value: Config.finnhubKey)
            ]
        }
        var resourceType: APIResourceType { .stockMetrics }
        var cacheKey: String { "metrics_\(symbol)" }
    }
    
    struct Search: PaginatedEndpoint {
        typealias Response = PaginatedResponse<StockLookup>
        
        let query: String
        let page: Int
        
        var baseURL: String { "https://finnhub.io/api/v1" }
        var path: String { "/search" }
        var queryItems: [URLQueryItem] {
            [
                .init(name: "q", value: query),
                .init(name: "token", value: Config.finnhubKey)
            ] + paginationQueryItems
        }
        var resourceType: APIResourceType { .stockLookup }
        var cacheKey: String { "search_\(query)" }
    }
    
    struct Lookup: APIEndpoint {
        typealias Response = StockLookupResponse
        let query: String
        
        var baseURL: String { "https://finnhub.io/api/v1" }
        var path: String { "/search" }
        var queryItems: [URLQueryItem] {
            [
                .init(name: "q", value: query),
                .init(name: "exchange", value: "US"),
                .init(name: "token", value: Config.finnhubKey)
            ]
        }
        var resourceType: APIResourceType { .stockLookup }
        var cacheKey: String { "lookup_\(query)" }
    }
}

extension FinnhubEndpoint.Search {
    var itemsPerPage: Int { 50 }
}

@MainActor
class Finnhub: ObservableObject {
    static let shared = Finnhub()
    @Published var allStocks: [Stock] = []
    private let client = APIClient.shared
    
    func fetchStockQuote(symbol: String) async throws -> StockQuote {
        let endpoint = FinnhubEndpoint.Quote(symbol: symbol)
        
        // Try cache first with background refresh
        if let cached = await APICache.shared.value(
            type: endpoint.resourceType,
            key: endpoint.cacheKey, backgroundRefresh: { [self] _ in
                try await self.client.send(endpoint)
            }) {
            switch cached {
            case .fresh(let quote), .stale(let quote):
                return quote
            }
        }
        
        // If not cached, fetch directly
        return try await self.client.send(endpoint)
    }
    
    func fetchStockMetrics(symbol: String) async throws -> StockMetrics? {
        let endpoint = FinnhubEndpoint.Metrics(symbol: symbol)
        
        // Try cache first with background refresh and retry logic
        if let cached = await APICache.shared.value(
            type: endpoint.resourceType,
            key: endpoint.cacheKey, backgroundRefresh: { _ in
                try await self.withRetry(maxAttempts: 3) {
                    try await self.client.send(endpoint)
                }
            }) {
            switch cached {
            case .fresh(let response), .stale(let response):
                return response.metric
            }
        }
        
        // If not cached, fetch with retry
        let response = try await withRetry(maxAttempts: 3) {
            try await client.send(endpoint)
        }
        
        return response.metric
    }
    
    func lookupStock(query: String) async throws -> StockLookup? {
        let endpoint = FinnhubEndpoint.Lookup(query: query)
        
        // Try cache first with background refresh and retry logic
        if let cached = await APICache.shared.value(
            type: endpoint.resourceType,
            key: endpoint.cacheKey, backgroundRefresh: { _ in
                try await self.withRetry(maxAttempts: 3) {
                    try await self.client.send(endpoint)
                }
            }) {
            switch cached {
            case .fresh(let response), .stale(let response):
                return response.result.first
            }
        }
        
        // If not cached, fetch with retry
        let response = try await withRetry(maxAttempts: 3) {
            try await client.send(endpoint)
        }
        return response.result.first
    }
    
    private func withRetry<T>(
        maxAttempts: Int,
        delay: TimeInterval = 1.0,
        task: () async throws -> T
    ) async throws -> T {
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                return try await task()
            } catch {
                attempts += 1
                lastError = error
                
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? URLError(.unknown)
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
            for symbol in batch {
                do {
                    let cachedMetadata = await cache.getCachedMetadata()[symbol]
                    
                    // Use async let to parallelize the requests
                    async let quote = fetchStockQuote(symbol: symbol)
                    async let metrics = cachedMetadata?.metrics != nil ? 
                        cachedMetadata?.metrics : 
                        try await fetchStockMetrics(symbol: symbol)
                    async let lookup = cachedMetadata?.lookup != nil ? 
                        cachedMetadata?.lookup : 
                        try await lookupStock(query: symbol)
                    
                    // Wait for all async operations to complete
                    let stock = try await Stock(
                        symbol: symbol,
                        quote: quote,
                        metrics: metrics,
                        lookup: lookup
                    )
                    
                    // Update on main actor since this is a published property
                    await MainActor.run {
                        stocks.append(stock)
                        allStocks.append(stock) // Update the published property
                    }
                    
                    // Cache the metadata
                    try await cache.cacheMetadata(symbol: symbol, lookup: lookup, metrics: metrics)
                } catch {
                    print("Error fetching stock data for \(symbol):", error)
                }
            }
        }
        
        return stocks
    }
    
    func searchStocks(query: String, page: Int = 1) async throws -> PaginatedResponse<StockLookup> {
        let endpoint = FinnhubEndpoint.Search(query: query, page: page)
        
        // Try cache first with background refresh
        if let cached = await APICache.shared.value(
            type: endpoint.resourceType,
            key: endpoint.paginatedCacheKey, backgroundRefresh: { [self] _ in
                try await self.client.send(endpoint)
            }) {
            switch cached {
            case .fresh(let response), .stale(let response):
                return response
            }
        }
        
        // If not cached or expired, fetch directly
        let response = try await self.client.send(endpoint)
        await APICache.shared.cache(response, type: endpoint.resourceType, key: endpoint.paginatedCacheKey)
        return response
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
