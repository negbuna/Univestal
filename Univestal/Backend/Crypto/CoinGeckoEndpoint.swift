import Foundation

enum CoinGeckoEndpoint {
    struct MarketData: PaginatedEndpoint {
        typealias Response = PaginatedResponse<Coin>
        
        let page: Int
        let itemsPerPage: Int = 50  // CoinGecko recommended page size
        
        var baseURL: String { "https://api.coingecko.com/api/v3" }
        var path: String { "/coins/markets" }
        var queryItems: [URLQueryItem] {
            [
                .init(name: "vs_currency", value: "usd"),
                .init(name: "sparkline", value: "true"),
                .init(name: "order", value: "market_cap_desc")
            ] + paginationQueryItems
        }
        var resourceType: APIResourceType { .cryptoPrice }
        var cacheKey: String { "markets" }
    }
    
    struct Search: PaginatedEndpoint {
        typealias Response = PaginatedResponse<Coin>
        
        let query: String
        let page: Int
        let itemsPerPage: Int = 50
        
        var baseURL: String { "https://api.coingecko.com/api/v3" }
        var path: String { "/search" }
        var queryItems: [URLQueryItem] {
            [
                .init(name: "query", value: query)
            ] + paginationQueryItems
        }
        var resourceType: APIResourceType { .cryptoDetails }
        var cacheKey: String { "search_\(query)" }
    }
}
