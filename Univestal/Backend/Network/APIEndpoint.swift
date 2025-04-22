import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case rateLimitExceeded
    case serverError(Int)
}

protocol APIEndpoint {
    associatedtype Response: Codable
    
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    var resourceType: APIResourceType { get }
    var cacheKey: String { get }
}

protocol PaginatedEndpoint: APIEndpoint {
    var page: Int { get }
    var itemsPerPage: Int { get }
    
    // Default implementations
    var paginationQueryItems: [URLQueryItem] { get }
    var paginatedCacheKey: String { get }
}

extension PaginatedEndpoint {
    var itemsPerPage: Int { 25 }  // Default page size
    
    var paginationQueryItems: [URLQueryItem] {
        [
            .init(name: "page", value: "\(page)"),
            .init(name: "per_page", value: "\(itemsPerPage)")
        ]
    }
    
    var paginatedCacheKey: String {
        "\(cacheKey)_page_\(page)"
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum RequestPriority: Int, Comparable, CaseIterable {
    case immediate = 0
    case high = 1
    case normal = 2
    case low = 3
    
    static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// Default implementations
extension APIEndpoint {
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
    
    func makeRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        components.path += path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        return request
    }
}
