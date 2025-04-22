import Foundation

actor APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    func send<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        // Try cache first
        if let cached: E.Response = await APICache.shared.value(
            type: endpoint.resourceType,
            key: endpoint.cacheKey
        ) {
            return cached
        }
        
        // Make request
        let request = try endpoint.makeRequest()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle response
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded = try decoder.decode(E.Response.self, from: data)
                // Cache successful response
                await APICache.shared.cache(decoded, type: endpoint.resourceType, key: endpoint.cacheKey)
                return decoded
            } catch {
                throw APIError.decodingFailed(error)
            }
        case 429:
            throw APIError.rateLimitExceeded
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}
